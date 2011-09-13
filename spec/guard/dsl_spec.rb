require 'spec_helper'
require 'guard/guard'

describe Guard::Dsl do
  subject { described_class }
  class Guard::Dummy < Guard::Guard; end

  before(:each) do
    @local_guardfile_path = File.join(Dir.pwd, 'Guardfile')
    @home_guardfile_path  = File.expand_path(File.join("~", ".Guardfile"))
    @user_config_path     = File.expand_path(File.join("~", ".guard.rb"))
    ::Guard.stub!(:options).and_return(:debug => true)
    ::Guard.stub!(:guards).and_return([mock('Guard')])
  end

  def self.disable_user_config
    before(:each) { File.stub(:exist?).with(@user_config_path) { false } }
  end

  describe "it should select the correct data source for Guardfile" do
    before(:each) { ::Guard::Dsl.stub!(:instance_eval_guardfile) }
    disable_user_config

    it "should use a string for initializing" do
      Guard::UI.should_not_receive(:error)
      lambda { subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string) }.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end

    it "should use a given file over the default loc" do
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

    it 'should append the user config file if present' do
      fake_guardfile('/abc/Guardfile', "guard :foo")
      fake_guardfile(@user_config_path, "guard :bar")
      Guard::UI.should_not_receive(:error)
      lambda { subject.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
        subject.guardfile_contents_with_user_config.should == "guard :foo\nguard :bar"
    end

  end

  it "displays an error message when no Guardfile is found" do
    subject.stub(:guardfile_default_path).and_return("no_guardfile_here")
    Guard::UI.should_receive(:error).with("No Guardfile found, please create one with `guard init`.")
    lambda { subject.evaluate_guardfile }.should raise_error
  end

  it "displays an error message when no guard are defined in Guardfile" do
    ::Guard::Dsl.stub!(:instance_eval_guardfile)
    ::Guard.stub!(:guards).and_return([])
    Guard::UI.should_receive(:error)
    subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string)
  end

  describe "correctly reads data from its valid data source" do
    before(:each) { ::Guard::Dsl.stub!(:instance_eval_guardfile) }
    disable_user_config

    it "reads correctly from a string" do
      lambda { subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string) }.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end

    it "reads correctly from a Guardfile" do
      fake_guardfile('/abc/Guardfile', "guard :foo" )

      lambda { subject.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
      subject.guardfile_contents.should == "guard :foo"
    end

    it "reads correctly from a Guardfile" do
      fake_guardfile(File.join(Dir.pwd, 'Guardfile'), valid_guardfile_string)

      lambda { subject.evaluate_guardfile }.should_not raise_error
      subject.guardfile_contents.should == valid_guardfile_string
    end
  end

  describe "correctly throws errors when initializing with invalid data" do
    before(:each) { ::Guard::Dsl.stub!(:instance_eval_guardfile) }

    it "raises error when there's a problem reading a file" do
      File.stub!(:exist?).with('/def/Guardfile') { true }
      File.stub!(:read).with('/def/Guardfile')   { raise Errno::EACCES.new("permission error") }

      Guard::UI.should_receive(:error).with(/^Error reading file/)
      lambda { subject.evaluate_guardfile(:guardfile => '/def/Guardfile') }.should raise_error
    end

    it "raises error when given Guardfile doesn't exist" do
      File.stub!(:exist?).with('/def/Guardfile') { false }

      Guard::UI.should_receive(:error).with(/No Guardfile exists at/)
      lambda { subject.evaluate_guardfile(:guardfile => '/def/Guardfile') }.should raise_error
    end

    it "raises error when resorting to use default, finds no default" do
      File.stub!(:exist?).with(@local_guardfile_path) { false }
      File.stub!(:exist?).with(@home_guardfile_path) { false }

      Guard::UI.should_receive(:error).with("No Guardfile found, please create one with `guard init`.")
      lambda { subject.evaluate_guardfile }.should raise_error
    end

    it "raises error when guardfile_content ends up empty or nil" do
      Guard::UI.should_receive(:error).with(/The command file/)
      lambda { subject.evaluate_guardfile(:guardfile_contents => "") }.should raise_error
    end

    it "doesn't raise error when guardfile_content is nil (skipped)" do
      Guard::UI.should_not_receive(:error)
      lambda { subject.evaluate_guardfile(:guardfile_contents => nil) }.should_not raise_error
    end
  end

  it "displays an error message when Guardfile is not valid" do
    Guard::UI.should_receive(:error).with(/Invalid Guardfile, original error is:/)

    lambda { subject.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string ) }.should raise_error
  end

  describe ".reevaluate_guardfile" do
    before(:each) { ::Guard::Dsl.stub!(:instance_eval_guardfile) }

    it "resets already definded guards before calling evaluate_guardfile" do
      Guard::Notifier.turn_off
      subject.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string)
      ::Guard.guards.should_not be_empty
      ::Guard::Dsl.should_receive(:evaluate_guardfile)
      subject.reevaluate_guardfile
      ::Guard.guards.should be_empty
    end
  end

  describe ".guardfile_default_path" do
    let(:local_path) { File.join(Dir.pwd, 'Guardfile') }
    let(:user_path) { File.expand_path(File.join("~", '.Guardfile')) }
    before(:each) { File.stub(:exist? => false) }

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

  describe "#ignore_paths" do
    disable_user_config
    
    it "adds the paths to the listener's ignore_paths" do
      ::Guard.stub!(:listener).and_return(mock('Listener'))
      ::Guard.listener.should_receive(:ignore_paths).and_return(ignore_paths = ['faz'])
      
      subject.evaluate_guardfile(:guardfile_contents => "ignore_paths 'foo', 'bar'")
      ignore_paths.should == ['faz', 'foo', 'bar']
    end
  end
  
  describe "#group" do
    disable_user_config

    it "evaluates only the specified string group" do
      ::Guard.should_receive(:add_guard).with(:pow, [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :group => :w })

      subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => ['w'])
    end

    it "evaluates only the specified symbol group" do
      ::Guard.should_receive(:add_guard).with(:pow, [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :group => :w })

      subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => [:w])
    end

    it "evaluates only the specified groups" do
      ::Guard.should_receive(:add_guard).with(:pow, [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with(:rspec, [], [], { :group => :x })
      ::Guard.should_receive(:add_guard).with(:ronn, [], [], { :group => :x })
      ::Guard.should_receive(:add_guard).with(:less, [], [], { :group => :y })

      subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => [:x, :y])
    end

    it "evaluates always guard outside any group (even when a group is given)" do
      ::Guard.should_receive(:add_guard).with(:pow, [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :group => :w })

      subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => [:w])
    end

    it "evaluates all groups when no group option is specified" do
      ::Guard.should_receive(:add_guard).with(:pow, [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :group => :w })
      ::Guard.should_receive(:add_guard).with(:rspec, [], [], { :group => :x })
      ::Guard.should_receive(:add_guard).with(:ronn, [], [], { :group => :x })
      ::Guard.should_receive(:add_guard).with(:less, [], [], { :group => :y })

      subject.evaluate_guardfile(:guardfile_contents => valid_guardfile_string)
    end
  end

  describe "#guard" do
    disable_user_config

    it "loads a guard specified as a quoted string from the DSL" do
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :group => :default })

      subject.evaluate_guardfile(:guardfile_contents => "guard 'test'")
    end

    it "loads a guard specified as a double quoted string from the DSL" do
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :group => :default })

      subject.evaluate_guardfile(:guardfile_contents => 'guard "test"')
    end

    it "loads a guard specified as a symbol from the DSL" do
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :group => :default })

      subject.evaluate_guardfile(:guardfile_contents => "guard :test")
    end

    it "loads a guard specified as a symbol and called with parens from the DSL" do
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :group => :default })

      subject.evaluate_guardfile(:guardfile_contents => "guard(:test)")
    end

    it "receives options when specified, from normal arg" do
      ::Guard.should_receive(:add_guard).with(:test, [], [], { :opt_a => 1, :opt_b => 'fancy', :group => :default })

      subject.evaluate_guardfile(:guardfile_contents => "guard 'test', :opt_a => 1, :opt_b => 'fancy'")
    end
  end

  describe "#watch" do
    disable_user_config

    it "should receive watchers when specified" do
      ::Guard.should_receive(:add_guard).with(:dummy, anything, anything, { :group => :default }) do |name, watchers, callbacks, options|
        watchers.size.should == 2
        watchers[0].pattern.should     == 'a'
        watchers[0].action.call.should == proc { 'b' }.call
        watchers[1].pattern.should     == 'c'
        watchers[1].action.should == nil
      end
      subject.evaluate_guardfile(:guardfile_contents => "
      guard :dummy do
         watch('a') { 'b' }
         watch('c')
      end")
    end
  end

  describe "#callback" do
    it "creates callbacks for the guard" do
      class MyCustomCallback
        def self.call(guard_class, event, args)
          # do nothing
        end
      end

      ::Guard.should_receive(:add_guard).with(:dummy, anything, anything, { :group => :default }) do |name, watchers, callbacks, options|
        callbacks.should have(2).items
        callbacks[0][:events].should   == :start_end
        callbacks[0][:listener].call(Guard::Dummy, :start_end, 'foo').should == "Guard::Dummy executed 'start_end' hook with foo!"
        callbacks[1][:events].should   == [:start_begin, :run_all_begin]
        callbacks[1][:listener].should == MyCustomCallback
      end
      subject.evaluate_guardfile(:guardfile_contents => '
        guard :dummy do
          callback(:start_end) { |guard_class, event, args| "#{guard_class} executed \'#{event}\' hook with #{args}!" }
          callback(MyCustomCallback, [:start_begin, :run_all_begin])
        end')
    end
  end

private

  def fake_guardfile(name, contents)
    File.stub!(:exist?).with(name) { true }
    File.stub!(:read).with(name)   { contents }
  end

  def valid_guardfile_string
    "
    guard :pow

    group 'w' do
      guard 'test'
    end

    group :x do
      guard 'rspec'
      guard :ronn
    end

    group 'y' do
      guard 'less'
    end
    "
  end

  def invalid_guardfile_string
   "Bad Guardfile"
  end
end
