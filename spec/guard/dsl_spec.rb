require 'spec_helper'

describe Guard::Dsl do
  subject { described_class }
  before(:each) do
    @local_guardfile_path = File.join(Dir.pwd, 'Guardfile')
    @home_guardfile_path  = File.expand_path(File.join("~", "Guardfile"))
    ::Guard.stub!(:options).and_return(:debug => true)
  end

  describe "it should select the correct data source for Guardfile" do

    before(:each) do
      ::Guard::Dsl.stub!(:instance_eval_guardfile)
    end

    it "should use a string for initializing" do
      Guard::UI.should_not_receive(:error)
      lambda { subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string) }.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end
    it "should use a -command file over the default loc" do
      fake_guardfile('/abc/Guardfile', "guard :foo")

      Guard::UI.should_not_receive(:error)
      lambda { subject.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
      subject.guardfile_contents.should == "guard :foo"
    end

    it "should use a default file if no other options are given" do
      fake_guardfile(@local_guardfile_path, "guard :bar")

      Guard::UI.should_not_receive(:error)
      lambda { subject.evaluate_guardfile }.should_not raise_error
      subject.guardfile_contents.should == "guard :bar"
    end

    it "should use a string over any other method" do
      fake_guardfile('/abc/Guardfile', "guard :foo")
      fake_guardfile(@local_guardfile_path, "guard :bar")

      Guard::UI.should_not_receive(:error)
      lambda { subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string) }.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end

    it "should use the given Guardfile over default Guardfile" do
      fake_guardfile('/abc/Guardfile', "guard :foo")
      fake_guardfile(@local_guardfile_path, "guard :bar")

      Guard::UI.should_not_receive(:error)
      lambda { subject.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
      subject.guardfile_contents.should == "guard :foo"
    end
  end

  it "displays an error message when no Guardfile is found" do
    subject.stub(:guardfile_default_path).and_return("no_guardfile_here")
    Guard::UI.should_receive(:error).with("No Guardfile found, please create one with `guard init`.")
    lambda { subject.evaluate_guardfile }.should raise_error
  end

  describe "it should correctly read data from its valid data source" do
    before(:each) do
      ::Guard::Dsl.stub!(:instance_eval_guardfile)
    end

    it "should read correctly from a string" do
      lambda { subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string) }.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end

    it "should read correctly from a Guardfile" do
      fake_guardfile('/abc/Guardfile', "guard :foo" )

      lambda { subject.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
      subject.guardfile_contents.should == "guard :foo"
    end

    it "should read correctly from a Guardfile" do
      fake_guardfile(File.join(Dir.pwd, 'Guardfile'), valid_guardfile_string)

      lambda { subject.evaluate_guardfile }.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end
  end

  describe "It should correctly throw errors when initializing with invalid data" do
    before(:each) do
      ::Guard::Dsl.stub!(:instance_eval_guardfile)
    end

    it "should raise error when there's a problem reading a file" do
      File.stub!(:exist?).with('/def/Guardfile') { true }
      File.stub!(:read).with('/def/Guardfile')   { raise Errno::EACCES.new("permission error") }

      Guard::UI.should_receive(:error).with(/^Error reading file/)
      lambda { subject.evaluate_guardfile(:guardfile => '/def/Guardfile') }.should raise_error
    end

    it "should raise error when -guardfile doesn't exist" do
      File.stub!(:exist?).with('/def/Guardfile') { false }

      Guard::UI.should_receive(:error).with(/No Guardfile exists at/)
      lambda { subject.evaluate_guardfile(:guardfile => '/def/Guardfile') }.should raise_error
    end

    it "should raise error when resorting to use default, finds no default" do
      File.stub!(:exist?).with(@local_guardfile_path) { false }
      File.stub!(:exist?).with(@home_guardfile_path) { false }

      Guard::UI.should_receive(:error).with("No Guardfile found, please create one with `guard init`.")
      lambda { subject.evaluate_guardfile }.should raise_error
    end

    it "should raise error when guardfile_content ends up empty or nil" do
      Guard::UI.should_receive(:error).twice.with(/The command file/)
      lambda { subject.evaluate_guardfile(:guardfile_contents => "") }.should raise_error
      lambda { subject.evaluate_guardfile(:guardfile_contents => nil) }.should raise_error
    end

  end

  it "displays an error message when Guardfile is not valid" do
    Guard::UI.should_receive(:error).with(/Invalid Guardfile, original error is:/)

    lambda { subject.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string ) }.should raise_error
  end

  describe ".guardfile_default_path" do
    let(:local_path) { File.join(Dir.pwd, 'Guardfile') }
    let(:user_path) { File.expand_path(File.join("~", 'Guardfile')) }

    before do
      File.stub(:exist? => false)
    end

    context "when there is a local Guardfile" do
      it "returns the path to the local Guardfile" do
        File.stub(:exist?).with(local_path).and_return(true)
        subject.guardfile_default_path.should == local_path
      end
    end

    context "when there is a Guardfile in the user's home directory" do
      it "returns the path to the user Guardfile" do
        File.stub(:exist?).with(user_path).and_return(true)
        subject.guardfile_default_path.should == user_path
      end
    end

    context "when there's both a local and user Guardfile" do
      it "returns the path to the local Guardfile" do
        File.stub(:exist?).with(local_path).and_return(true)
        File.stub(:exist?).with(user_path).and_return(true)
        subject.guardfile_default_path.should == local_path
      end
    end

  end

  describe ".guardfile_include?" do
    it "detects a guard specified by a string with double quotes" do
      subject.stub(:guardfile_contents => 'guard "test" {watch("c")}')

      subject.guardfile_include?('test').should be_true
    end

    it "detects a guard specified by a string with single quote" do
      subject.stub(:guardfile_contents => 'guard \'test\' {watch("c")}')

      subject.guardfile_include?('test').should be_true
    end

    it "detects a guard specified by a symbol" do
      subject.stub(:guardfile_contents => 'guard :test {watch("c")}')

      subject.guardfile_include?('test').should be_true
    end

    it "detects a guard wrapped in parentheses" do
      subject.stub(:guardfile_contents => 'guard(:test) {watch("c")}')

      subject.guardfile_include?('test').should be_true
    end
  end

  describe "#group" do
    it "should evaluates only the specified group" do
      ::Guard.should_receive(:add_guard).with('test', anything, {})
      lambda { subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => ['x']) }.should_not raise_error
    end
    it "should evaluates only the specified groups" do
      ::Guard.should_receive(:add_guard).with('test', anything, {})
      ::Guard.should_receive(:add_guard).with('another', anything, {})
      lambda { subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => ['x','y']) }.should_not raise_error
    end
  end

  # TODO: not sure if each seperate quoting/call type needs its own test
  describe "#guard" do
    it "should load a guard specified as a quoted string from the DSL" do
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
      guardfile_with_watchers = "guard 'test' do
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
      subject.evaluate_guardfile(:guardfile_contents => guardfile_with_watchers)
    end
  end

private

  def fake_guardfile(name, contents)
    File.stub!(:exist?).with(name) { true }
    File.stub!(:read).with(name)   { contents }
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

  def mock_guardfile_content(content)
    File.stub!(:read).with(subject.guardfile_default_path) { content }
  end

  def invalid_guardfile_string
   "Bad Guardfile"
  end
end
