require 'spec_helper'
require 'guard/guard'

describe Guard::Dsl do

  class Guard::Dummy < Guard::Guard; end

  before(:each) do
    @local_guardfile_path = File.join(Dir.pwd, 'Guardfile')
    @home_guardfile_path  = File.expand_path(File.join("~", ".Guardfile"))
    @user_config_path     = File.expand_path(File.join("~", ".guard.rb"))
    ::Guard.setup
    ::Guard.stub!(:options).and_return(:verbose => true)
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
      lambda { described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string) }.should_not raise_error
      described_class.guardfile_contents.should == valid_guardfile_string
    end

    it "should use a given file over the default loc" do
      fake_guardfile('/abc/Guardfile', "guard :foo")

      Guard::UI.should_not_receive(:error)
      lambda { described_class.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
      described_class.guardfile_contents.should == "guard :foo"
    end

    it "should use a default file if no other options are given" do
      fake_guardfile(@local_guardfile_path, "guard :bar")

      Guard::UI.should_not_receive(:error)
      lambda { described_class.evaluate_guardfile }.should_not raise_error
      described_class.guardfile_contents.should == "guard :bar"
    end

    it "should use a string over any other method" do
      fake_guardfile('/abc/Guardfile', "guard :foo")
      fake_guardfile(@local_guardfile_path, "guard :bar")

      Guard::UI.should_not_receive(:error)
      lambda { described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string) }.should_not raise_error
      described_class.guardfile_contents.should == valid_guardfile_string
    end

    it "should use the given Guardfile over default Guardfile" do
      fake_guardfile('/abc/Guardfile', "guard :foo")
      fake_guardfile(@local_guardfile_path, "guard :bar")

      Guard::UI.should_not_receive(:error)
      lambda { described_class.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
      described_class.guardfile_contents.should == "guard :foo"
    end

    it 'should append the user config file if present' do
      fake_guardfile('/abc/Guardfile', "guard :foo")
      fake_guardfile(@user_config_path, "guard :bar")
      Guard::UI.should_not_receive(:error)
      lambda { described_class.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
      described_class.guardfile_contents_with_user_config.should == "guard :foo\nguard :bar"
    end

  end

  it "displays an error message when no Guardfile is found" do
    described_class.stub(:guardfile_default_path).and_return("no_guardfile_here")
    Guard::UI.should_receive(:error).with("No Guardfile found, please create one with `guard init`.")
    lambda { described_class.evaluate_guardfile }.should raise_error
  end

  it "displays an error message when no guard are defined in Guardfile" do
    ::Guard::Dsl.stub!(:instance_eval_guardfile)
    ::Guard.stub!(:guards).and_return([])
    Guard::UI.should_receive(:error)
    described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string)
  end

  describe "correctly reads data from its valid data source" do
    before(:each) { ::Guard::Dsl.stub!(:instance_eval_guardfile) }
    disable_user_config

    it "reads correctly from a string" do
      lambda { described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string) }.should_not raise_error
      described_class.guardfile_contents.should == valid_guardfile_string
    end

    it "reads correctly from a Guardfile" do
      fake_guardfile('/abc/Guardfile', "guard :foo" )

      lambda { described_class.evaluate_guardfile(:guardfile => '/abc/Guardfile') }.should_not raise_error
      described_class.guardfile_contents.should == "guard :foo"
    end

    it "reads correctly from a Guardfile" do
      fake_guardfile(File.join(Dir.pwd, 'Guardfile'), valid_guardfile_string)

      lambda { described_class.evaluate_guardfile }.should_not raise_error
      described_class.guardfile_contents.should == valid_guardfile_string
    end
  end

  describe "correctly throws errors when initializing with invalid data" do
    before(:each) { ::Guard::Dsl.stub!(:instance_eval_guardfile) }

    it "raises error when there's a problem reading a file" do
      File.stub!(:exist?).with('/def/Guardfile') { true }
      File.stub!(:read).with('/def/Guardfile')   { raise Errno::EACCES.new("permission error") }

      Guard::UI.should_receive(:error).with(/^Error reading file/)
      lambda { described_class.evaluate_guardfile(:guardfile => '/def/Guardfile') }.should raise_error
    end

    it "raises error when given Guardfile doesn't exist" do
      File.stub!(:exist?).with('/def/Guardfile') { false }

      Guard::UI.should_receive(:error).with(/No Guardfile exists at/)
      lambda { described_class.evaluate_guardfile(:guardfile => '/def/Guardfile') }.should raise_error
    end

    it "raises error when resorting to use default, finds no default" do
      File.stub!(:exist?).with(@local_guardfile_path) { false }
      File.stub!(:exist?).with(@home_guardfile_path) { false }

      Guard::UI.should_receive(:error).with("No Guardfile found, please create one with `guard init`.")
      lambda { described_class.evaluate_guardfile }.should raise_error
    end

    it "raises error when guardfile_content ends up empty or nil" do
      Guard::UI.should_receive(:error).with(/The command file/)
      lambda { described_class.evaluate_guardfile(:guardfile_contents => "") }.should raise_error
    end

    it "doesn't raise error when guardfile_content is nil (skipped)" do
      Guard::UI.should_not_receive(:error)
      lambda { described_class.evaluate_guardfile(:guardfile_contents => nil) }.should_not raise_error
    end
  end

  it "displays an error message when Guardfile is not valid" do
    Guard::UI.should_receive(:error).with(/Invalid Guardfile, original error is:/)

    lambda { described_class.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string ) }.should raise_error
  end

  describe ".reevaluate_guardfile" do
    before(:each) { ::Guard::Dsl.stub!(:instance_eval_guardfile) }

    it "stops already defined guard before calling evaluate_guardfile" do
      Guard::Notifier.turn_off
      described_class.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string)

      ::Guard.guards.should_not be_empty
      ::Guard.guards.each do |guard|
        ::Guard.should_receive(:run_supervised_task).with(guard, :stop)
      end
      ::Guard::Dsl.should_receive(:evaluate_guardfile)

      described_class.reevaluate_guardfile
    end

    it "resets already defined guards before calling evaluate_guardfile" do
      Guard::Notifier.turn_off
      described_class.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string)

      ::Guard.guards.should_not be_empty
      ::Guard::Dsl.should_receive(:evaluate_guardfile)

      described_class.reevaluate_guardfile

      ::Guard.guards.should be_empty
    end

    it "resets groups before calling evaluate_guardfile" do
      Guard::Notifier.turn_off
      described_class.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string)

      ::Guard.groups.should_not be_empty
      ::Guard::Dsl.should_receive(:evaluate_guardfile)

      described_class.reevaluate_guardfile

      ::Guard.groups.should_not be_empty
      ::Guard.groups[0].name.should eql :default
      ::Guard.groups[0].options.should == {}
    end

    it "resets notifications before calling evaluate_guardfile" do
      Guard::Notifier.turn_off
      Guard::Notifier.notifications = [{ :name => :growl }]
      described_class.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string)

      ::Guard::Notifier.notifications.should_not be_empty
      ::Guard::Dsl.should_receive(:evaluate_guardfile)

      described_class.reevaluate_guardfile

      ::Guard::Notifier.notifications.should be_empty
    end

    # Tricky because ::Guard.guards is reset during reevaluate_guardfile so we can't mocking it. Any idea?
    pending "starts new defined guard after calling evaluate_guardfile" do
      Guard::Notifier.turn_off
      described_class.evaluate_guardfile(:guardfile_contents => invalid_guardfile_string)

      ::Guard::Dsl.should_receive(:evaluate_guardfile)
      ::Guard.guards.should_not be_empty
      ::Guard.guards.each do |guard|
        ::Guard.should_receive(:run_supervised_task).with(guard, :stop)
        ::Guard.should_receive(:run_supervised_task).with(any_args(), :start)
      end

      described_class.reevaluate_guardfile
    end
  end

  describe ".guardfile_default_path" do
    let(:local_path) { File.join(Dir.pwd, 'Guardfile') }
    let(:user_path) { File.expand_path(File.join("~", '.Guardfile')) }
    before(:each) { File.stub(:exist? => false) }

    context "when there is a local Guardfile" do
      it "returns the path to the local Guardfile" do
        File.stub(:exist?).with(local_path).and_return(true)
        described_class.guardfile_default_path.should == local_path
      end
    end

    context "when there is a Guardfile in the user's home directory" do
      it "returns the path to the user Guardfile" do
        File.stub(:exist?).with(user_path).and_return(true)
        described_class.guardfile_default_path.should == user_path
      end
    end

    context "when there's both a local and user Guardfile" do
      it "returns the path to the local Guardfile" do
        File.stub(:exist?).with(local_path).and_return(true)
        File.stub(:exist?).with(user_path).and_return(true)
        described_class.guardfile_default_path.should == local_path
      end
    end
  end

  describe ".guardfile_include?" do
    it "detects a guard specified by a string with double quotes" do
      described_class.stub(:guardfile_contents => 'guard "test" {watch("c")}')

      described_class.guardfile_include?('test').should be_true
    end

    it "detects a guard specified by a string with single quote" do
      described_class.stub(:guardfile_contents => 'guard \'test\' {watch("c")}')

      described_class.guardfile_include?('test').should be_true
    end

    it "detects a guard specified by a symbol" do
      described_class.stub(:guardfile_contents => 'guard :test {watch("c")}')

      described_class.guardfile_include?('test').should be_true
    end

    it "detects a guard wrapped in parentheses" do
      described_class.stub(:guardfile_contents => 'guard(:test) {watch("c")}')

      described_class.guardfile_include?('test').should be_true
    end
  end

  describe "#ignore_paths" do
    disable_user_config

    it "adds the paths to the listener's ignore_paths" do
      ::Guard.stub!(:listener).and_return(mock('Listener'))
      ::Guard.listener.should_receive(:ignore_paths).and_return(ignore_paths = ['faz'])

      described_class.evaluate_guardfile(:guardfile_contents => "ignore_paths 'foo', 'bar'")
      ignore_paths.should == ['faz', 'foo', 'bar']
    end
  end

  describe "#notification" do
    disable_user_config

    it 'adds a notification to the notifier' do
      ::Guard::Notifier.should_receive(:add_notification).with(:growl, {}, false)
      described_class.evaluate_guardfile(:guardfile_contents => 'notification :growl')
    end

    it 'adds multiple notification to the notifier' do
      ::Guard::Notifier.should_receive(:add_notification).with(:growl, {}, false)
      ::Guard::Notifier.should_receive(:add_notification).with(:ruby_gntp, { :host => '192.168.1.5' }, false)
      described_class.evaluate_guardfile(:guardfile_contents => "notification :growl\nnotification :ruby_gntp, :host => '192.168.1.5'")
    end
  end

  describe "#interactor" do
    disable_user_config

    it 'sets the interactor implementation' do
      ::Guard::Interactor.should_receive(:interactor=).with(:readline)
      described_class.evaluate_guardfile(:guardfile_contents => 'interactor :readline')
    end

    it 'converts the interactor to a symbol' do
      ::Guard::Interactor.should_receive(:interactor=).with(:readline)
      described_class.evaluate_guardfile(:guardfile_contents => 'interactor "readline"')
    end
  end

  describe "#group" do
    disable_user_config

    it "evaluates only the specified string group" do
      ::Guard.should_receive(:add_guard).with('pow', [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with('test', [], [], { :group => :w })

      described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => [:w])
    end

    it "evaluates only the specified symbol group" do
      ::Guard.should_receive(:add_guard).with('pow', [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with('test', [], [], { :group => :w })

      described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => [:w])
    end

    it "evaluates only the specified groups (with their options)" do
      ::Guard.should_receive(:add_guard).with('pow', [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with('rspec', [], [], { :group => :x })
      ::Guard.should_receive(:add_guard).with('ronn', [], [], { :group => :x })
      ::Guard.should_receive(:add_guard).with('less', [], [], { :group => :y })

      described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => [:x, :y])
    end

    it "evaluates always guard outside any group (even when a group is given)" do
      ::Guard.should_receive(:add_guard).with('pow', [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with('test', [], [], { :group => :w })

      described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string, :group => [:w])
    end

    it "evaluates all groups when no group option is specified (with their options)" do
      ::Guard.should_receive(:add_guard).with('pow', [], [], { :group => :default })
      ::Guard.should_receive(:add_guard).with('test', [], [], { :group => :w })
      ::Guard.should_receive(:add_guard).with('rspec', [], [], { :group => :x })
      ::Guard.should_receive(:add_guard).with('ronn', [], [], { :group => :x })
      ::Guard.should_receive(:add_guard).with('less', [], [], { :group => :y })

      described_class.evaluate_guardfile(:guardfile_contents => valid_guardfile_string)
    end
  end

  describe "#guard" do
    disable_user_config

    it "loads a guard specified as a quoted string from the DSL" do
      ::Guard.should_receive(:add_guard).with('test', [], [], { :group => :default })

      described_class.evaluate_guardfile(:guardfile_contents => "guard 'test'")
    end

    it "loads a guard specified as a double quoted string from the DSL" do
      ::Guard.should_receive(:add_guard).with('test', [], [], { :group => :default })

      described_class.evaluate_guardfile(:guardfile_contents => 'guard "test"')
    end

    it "loads a guard specified as a symbol from the DSL" do
      ::Guard.should_receive(:add_guard).with('test', [], [], { :group => :default })

      described_class.evaluate_guardfile(:guardfile_contents => "guard :test")
    end

    it "loads a guard specified as a symbol and called with parens from the DSL" do
      ::Guard.should_receive(:add_guard).with('test', [], [], { :group => :default })

      described_class.evaluate_guardfile(:guardfile_contents => "guard(:test)")
    end

    it "receives options when specified, from normal arg" do
      ::Guard.should_receive(:add_guard).with('test', [], [], { :opt_a => 1, :opt_b => 'fancy', :group => :default })

      described_class.evaluate_guardfile(:guardfile_contents => "guard 'test', :opt_a => 1, :opt_b => 'fancy'")
    end
  end

  describe "#watch" do
    disable_user_config

    it "should receive watchers when specified" do
      ::Guard.should_receive(:add_guard).with('dummy', anything, anything, { :group => :default }) do |name, watchers, callbacks, options|
        watchers.size.should eq 2
        watchers[0].pattern.should        eq 'a'
        watchers[0].action.call.should    eq proc { 'b' }.call
        watchers[1].pattern.should        eq 'c'
        watchers[1].action.should be_nil
      end
      described_class.evaluate_guardfile(:guardfile_contents => "
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

      ::Guard.should_receive(:add_guard).with('dummy', anything, anything, { :group => :default }) do |name, watchers, callbacks, options|
        callbacks.should have(2).items
        callbacks[0][:events].should    eq :start_end
        callbacks[0][:listener].call(Guard::Dummy, :start_end, 'foo').should eq "Guard::Dummy executed 'start_end' hook with foo!"
        callbacks[1][:events].should eq [:start_begin, :run_all_begin]
        callbacks[1][:listener].should eq MyCustomCallback
      end
      described_class.evaluate_guardfile(:guardfile_contents => '
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
    notification :growl

    guard :pow

    group :w do
      guard :test
    end

    group :x, :halt_on_fail => true do
      guard :rspec
      guard :ronn
    end

    group :y do
      guard :less
    end
    "
  end

  def invalid_guardfile_string
   "Bad Guardfile"
  end
end
