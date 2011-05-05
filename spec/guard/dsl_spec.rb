require 'spec_helper'

describe Guard::Dsl do
  subject { Guard::Dsl }
  before(:each) do
    @default_guardfile = File.join(Dir.pwd, 'Guardfile')
    opt_hash = {:debug => true}
    ::Guard.stub!(:options).and_return opt_hash
  end

  describe "it should select the correct data source for Guardfile" do

    before(:each) do
      ::Guard::Dsl.stub!(:instance_eval_guardfile)
    end

    it "should use a string for initializing" do
      Guard::UI.should_not_receive(:error)
      lambda {subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string)}.should_not raise_error
      subject.actual_guardfile.should == 'options[:guardfile_contents]'
    end
    it "should use a -command file over the default loc" do
      fake_guardfile('/abc/Guardfile', valid_guardfile_string )

      Guard::UI.should_not_receive(:error)
      lambda {subject.evaluate_guardfile(:guardfile => '/abc/Guardfile')}.should_not raise_error
      subject.actual_guardfile.should == '/abc/Guardfile'
    end
    it "should use a default file if no other options are given" do
      fake_guardfile(@default_guardfile, valid_guardfile_string)
      Guard::UI.should_not_receive(:error)
      lambda {subject.evaluate_guardfile()}.should_not raise_error
      subject.actual_guardfile.should == @default_guardfile
    end
    
    it "should use a string over any other method" do
      fake_guardfile('/abc/Guardfile', valid_guardfile_string )

      fake_guardfile(@default_guardfile, valid_guardfile_string)

      Guard::UI.should_not_receive(:error)
      lambda {subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string)}.should_not raise_error
      subject.actual_guardfile.should == 'options[:guardfile_contents]'
    end
    
    it "should use a guardfile over any the default" do
      fake_guardfile('/abc/Guardfile', valid_guardfile_string )

      fake_guardfile(@default_guardfile, valid_guardfile_string)

      Guard::UI.should_not_receive(:error)
      lambda {subject.evaluate_guardfile(:guardfile => '/abc/Guardfile')}.should_not raise_error
      subject.actual_guardfile.should == '/abc/Guardfile'
    end
  end

  describe "it should correctly read data from its valid data source" do
    before(:each) do
      ::Guard::Dsl.stub!(:instance_eval_guardfile)
    end

    it "should read correctly from a string" do
      lambda {subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string)}.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end

    it "should read correctly from a guardfile" do
      fake_guardfile('/abc/Guardfile', valid_guardfile_string )

      lambda {subject.evaluate_guardfile(:guardfile => '/abc/Guardfile')}.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end

    it "should read correctly from a guardfile" do
      my_default = File.join(Dir.pwd, 'Guardfile')
      fake_guardfile(my_default, valid_guardfile_string)
      lambda {subject.evaluate_guardfile()}.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end
  end

  describe "It should correctly throw errors when initializing with invalid data" do
    before(:each) do
      ::Guard::Dsl.stub!(:instance_eval_guardfile)
    end
    
    it "should raise error when there's a problem reading a file" do
      File.stub!(:exist?).with('/def/Guardfile') { true }
      File.stub!(:read).with('/def/Guardfile') { raise Errno::EACCES.new("permission error") }

      Guard::UI.should_receive(:error).with(/^Error reading file/)
      lambda {subject.evaluate_guardfile(:guardfile=>'/def/Guardfile')}.should raise_error
    end 

    it "should raise error when -guardfile doesn't exist" do
      File.stub!(:exist?).with('/def/Guardfile') { false }

      Guard::UI.should_receive(:error).with(/No Guardfile exists at/)
      lambda {subject.evaluate_guardfile(:guardfile=>'/def/Guardfile')}.should raise_error
    end

    it "should raise error when resorting to use default, finds no default" do
      File.stub!(:exist?).with(@default_guardfile) { false }

      Guard::UI.should_receive(:error).with(/No Guardfile in current folder/)
      lambda {subject.evaluate_guardfile()}.should raise_error
    end

    it "should raise error when guardfile_content ends up empty or nil" do
      Guard::UI.should_receive(:error).twice.with(/The command file/)
      lambda {subject.evaluate_guardfile(:guardfile_contents => "")}.should raise_error
      lambda {subject.evaluate_guardfile(:guardfile_contents => nil)}.should raise_error
    end
     
  end
  
  it "displays an error message when Guardfile is not valid" do
    Guard::UI.should_receive(:error).with(/Invalid Guardfile, original error is:/)
    lambda {subject.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string )}.should raise_error
  end

  describe ".guardfile_include?" do
    it "detects a guard specified by a string with double quotes" do
      subject.guardfile_include?('test', 'guard "test" {watch("c")}').should be_true
    end
    it "detects a guard specified by a string with single quote" do
      subject.guardfile_include?('test', 'guard \'test\' {watch("c")}').should be_true
    end
    it "detects a guard specified by a symbol" do
      subject.guardfile_include?('test', 'guard :test {watch("c")}').should be_true
    end
    it "detects a guard wrapped in parentheses" do
      subject.guardfile_include?('test', 'guard(:test) {watch("c")}').should be_true
    end
  end

  describe "#group" do
    it "should evaluates only the specified group" do
      ::Guard.should_receive(:add_guard).with('test', anything, {})
      lambda {subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group=>['x'])}.should_not raise_error
    end
    it "should evaluates only the specified groups" do
      ::Guard.should_receive(:add_guard).with('test', anything, {})
      ::Guard.should_receive(:add_guard).with('another', anything, {})
      lambda {subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group=>['x','y'])}.should_not raise_error
    end
  end

  #TODO not sure if each seperate quoting/call type needs its own test
  describe "#guard" do
    it "should load a guard specified as a single quoted string from the DSL" do
      ::Guard.should_receive(:add_guard).with('test', [], {})
      subject.evaluate_guardfile(:guardfile_contents => "guard 'test'")
    end
    it "should load a guard specified as a single quoted string from the DSL" do
      ::Guard.should_receive(:add_guard).with('test', [], {})
      subject.evaluate_guardfile(:guardfile_contents => "guard 'test'")
    end
    it "should load a guard specified as a symbol from the DSL" do
      ::Guard.should_receive(:add_guard).with(:test, [], {})
      subject.evaluate_guardfile(:guardfile_contents => "guard :test")
    end
    it "should load a guard specified as a symbol and called with parens from the DSL" do
      ::Guard.should_receive(:add_guard).with(:test, [], {})
      subject.evaluate_guardfile(:guardfile_contents => "guard(:test)")
    end
    it "should receive options when specified" do
      ::Guard.should_receive(:add_guard).with('test', anything, { :opt_a => 1, :opt_b => 'fancy' })
      subject.evaluate_guardfile(:guardfile_contents => "guard 'test', :opt_a => 1, :opt_b => 'fancy'")
    end
    
  end

  describe "#watch" do
    it "should receive watchers when specified" do
      gf_with_watchers = "guard 'test' do
          watch('a') { 'b' }
          watch('c')
        end"

      ::Guard.should_receive(:add_guard).with('test', anything, {}) do |name, watchers, options|
        watchers.size.should == 2
        watchers[0].pattern.should     == 'a'
        watchers[0].action.call.should == proc { 'b' }.call
        watchers[1].pattern.should     == 'c'
        watchers[1].action.should == nil
      end
      subject.evaluate_guardfile(:guardfile_contents => gf_with_watchers)
    end
  end

private
  def fake_guardfile(name, contents)
    File.stub!(:exist?).with(name) { true }
    File.stub!(:read).with(name) { contents }
  end

  def valid_guardfile_string
   "group 'x' do
      guard 'test' do
        watch('c')
      end
    end

    group 'y' do
      guard 'another' do
        watch('c')
      end
    end

    group 'z' do
      guard 'another' do
        watch('c')
      end
    end"
  end

  def invalid_guardfile_string
   "Bad guardfile"
  end
end