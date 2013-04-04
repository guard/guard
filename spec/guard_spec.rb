require 'spec_helper'

describe Guard do
  before do
    ::Guard::Interactor.stub(:fabricate)
    Dir.stub(:chdir)
  end

  describe ".setup" do
    let(:options) { { :my_opts => true, :guardfile => File.join(@fixture_path, "Guardfile") } }
    subject { ::Guard.setup(options) }

    it "returns itself for chaining" do
      subject.should be ::Guard
    end

    it "initializes the plugins" do
      subject.guards.should eq []
    end

    it "initializes the groups" do
      subject.groups[0].name.should eq :default
      subject.groups[0].options.should == { }
    end

    it "initializes the options" do
      subject.options.should include(:my_opts)
    end

    it "initializes the listener" do
      subject.listener.should be_kind_of(Listen::Listener)
    end

    it "respect the watchdir option" do
      ::Guard.setup(:watchdir => '/usr')

      ::Guard.listener.directory.should eq '/usr'
    end

    it "changes the current work dir to the watchdir" do
      Dir.should_receive(:chdir).with('/tmp')
      ::Guard.setup(:watchdir => '/tmp')
    end

    it "call setup_signal_traps" do
      ::Guard.should_receive(:setup_signal_traps)
      subject
    end

    it "evaluates the DSL" do
      ::Guard::Dsl.should_receive(:evaluate_guardfile).with(options)
      subject
    end

    it "displays an error message when no guard are defined in Guardfile" do
      ::Guard::UI.should_receive(:error).with('No guards found in Guardfile, please add at least one.')
      subject
    end

    it "call setup_notifier" do
      ::Guard.should_receive(:setup_notifier)
      subject
    end

    it "call setup_interactor" do
      ::Guard.should_receive(:setup_interactor)
      subject
    end

    context 'without the group or plugin option' do
      it "initializes the empty scope" do
        subject.scope.should == { :groups => [], :plugins => [] }
      end
    end

    context 'with the group option' do
      let(:options) { {
        :group              => ['backend', 'frontend'],
        :guardfile_contents => "group :backend do; end; group :frontend do; end; group :excluded do; end"
      } }

      it "initializes the group scope" do
        subject.scope[:plugins].should be_empty
        subject.scope[:groups].count.should be 2
        subject.scope[:groups][0].name.should eql :backend
        subject.scope[:groups][1].name.should eql :frontend
      end
    end

    context 'with the plugin option' do
      let(:options) { {
        :plugin             => ['cucumber', 'jasmine'],
        :guardfile_contents => "guard :jasmine do; end; guard :cucumber do; end; guard :coffeescript do; end"
      } }

      before do
        stub_const 'Guard::Jasmine', Class.new(Guard::Guard)
        stub_const 'Guard::Cucumber', Class.new(Guard::Guard)
        stub_const 'Guard::CoffeeScript', Class.new(Guard::Guard)
      end

      it "initializes the plugin scope" do
        subject.scope[:groups].should be_empty
        subject.scope[:plugins].count.should be 2
        subject.scope[:plugins][0].class.should eql ::Guard::Cucumber
        subject.scope[:plugins][1].class.should eql ::Guard::Jasmine
      end
    end

    context 'when deprecations should be shown' do
      let(:options) { { :show_deprecations => true, :guardfile => File.join(@fixture_path, "Guardfile") } }
      subject { ::Guard.setup(options) }
      let(:runner) { mock('runner') }

      it 'calls the runner show deprecations' do
        ::Guard::Runner.should_receive(:new).and_return runner
        runner.should_receive(:deprecation_warning)
        subject
      end
    end

    context 'with the debug mode turned on' do
      let(:options) { { :debug => true, :guardfile => File.join(@fixture_path, "Guardfile") } }
      subject { ::Guard.setup(options) }

      it "logs command execution if the debug option is true" do
        ::Guard.should_receive(:debug_command_execution)
        subject
      end

      it "sets the log level to :debug if the debug option is true" do
        subject
        ::Guard::UI.options[:level].should eql :debug
      end
    end
  end

  describe ".setup_signal_traps", :speed => 'slow' do
    before { ::Guard::Dsl.stub(:evaluate_guardfile) }

    unless windows? || defined?(JRUBY_VERSION)
      context 'when receiving SIGUSR1' do
        context 'when Guard is running' do
          before { ::Guard.listener.should_receive(:paused?).and_return false }

          it 'pauses Guard' do
            ::Guard.should_receive(:pause)
            Process.kill :USR1, Process.pid
            sleep 1
          end
        end

        context 'when Guard is already paused' do
          before { ::Guard.listener.should_receive(:paused?).and_return true }

          it 'does not pauses Guard' do
            ::Guard.should_not_receive(:pause)
            Process.kill :USR1, Process.pid
            sleep 1
          end
        end
      end

      context 'when receiving SIGUSR2' do
        context 'when Guard is paused' do
          before { ::Guard.listener.should_receive(:paused?).and_return true }

          it 'un-pause Guard' do
            ::Guard.should_receive(:pause)
            Process.kill :USR2, Process.pid
            sleep 1
          end
        end

        context 'when Guard is already running' do
          before { ::Guard.listener.should_receive(:paused?).and_return false }

          it 'does not un-pause Guard' do
            ::Guard.should_not_receive(:pause)
            Process.kill :USR2, Process.pid
            sleep 1
          end
        end
      end

      context 'when receiving SIGINT' do
        context 'without an interactor' do
          before { ::Guard.should_receive(:interactor).and_return nil }

          it 'stops Guard' do
            ::Guard.should_receive(:stop)
            Process.kill :INT, Process.pid
            sleep 1
          end
        end

        context 'with an interactor' do
          let(:interactor) { mock('interactor', :thread => mock('thread')) }
          before { ::Guard.should_receive(:interactor).twice.and_return interactor }

          it 'delegates to the Pry thread' do
            interactor.thread.should_receive(:raise).with Interrupt
            Process.kill :INT, Process.pid
            sleep 1
          end
        end
      end
    end

    context "with the notify option enabled" do
      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV["GUARD_NOTIFY"] = nil }

        it "turns on the notifier on" do
          ::Guard::Notifier.should_receive(:turn_on)
          ::Guard.setup(:notify => true)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV["GUARD_NOTIFY"] = 'true' }

        it "turns on the notifier on" do
          ::Guard::Notifier.should_receive(:turn_on)
          ::Guard.setup(:notify => true)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV["GUARD_NOTIFY"] = 'false' }

        it "turns on the notifier off" do
          ::Guard::Notifier.should_receive(:turn_off)
          ::Guard.setup(:notify => true)
        end
      end
    end

    context "with the notify option disable" do
      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV["GUARD_NOTIFY"] = nil }

        it "turns on the notifier off" do
          ::Guard::Notifier.should_receive(:turn_off)
          ::Guard.setup(:notify => false)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV["GUARD_NOTIFY"] = 'true' }

        it "turns on the notifier on" do
          ::Guard::Notifier.should_receive(:turn_off)
          ::Guard.setup(:notify => false)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV["GUARD_NOTIFY"] = 'false' }

        it "turns on the notifier off" do
          ::Guard::Notifier.should_receive(:turn_off)
          ::Guard.setup(:notify => false)
        end
      end
    end
  end

  describe ".setup_listener" do
    let(:listener) { stub.as_null_object }

    context "with latency option" do
      before { ::Guard.stub(:options).and_return("latency" => 1.5) }

      it "pass option to listener" do
        Listen.should_receive(:to).with(anything, { :relative_paths => true, :latency => 1.5 }) { listener }
        ::Guard.setup_listener
      end
    end

    context "with force_polling option" do
      before { ::Guard.stub(:options).and_return("force_polling" => true) }

      it "pass option to listener" do
        Listen.should_receive(:to).with(anything, { :relative_paths => true, :force_polling => true }) { listener }
        ::Guard.setup_listener
      end
    end
  end

  describe ".setup_notifier" do
    context "with the notify option enabled" do
      before { ::Guard.stub(:options).and_return(:notify => true) }

      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV["GUARD_NOTIFY"] = nil }

        it_should_behave_like 'notifier enabled'
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV["GUARD_NOTIFY"] = 'true' }

        it_should_behave_like 'notifier enabled'
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV["GUARD_NOTIFY"] = 'false' }

        it_should_behave_like 'notifier disabled'
      end
    end

    context "with the notify option disabled" do
      before do
        ::Guard.stub(:options).and_return(:notify => false)
      end

      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV["GUARD_NOTIFY"] = nil }

        it_should_behave_like 'notifier disabled'
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV["GUARD_NOTIFY"] = 'true' }

        it_should_behave_like 'notifier disabled'
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV["GUARD_NOTIFY"] = 'false' }

        it_should_behave_like 'notifier disabled'
      end
    end
  end

  describe ".setup_interactor" do
    context 'with CLI options' do
      before do
        @enabled                    = ::Guard::Interactor.enabled
        ::Guard::Interactor.enabled = true
      end

      after { ::Guard::Interactor.enabled = @enabled }

      context "with interactions enabled" do
        before { ::Guard.setup(:no_interactions => false) }

        it_should_behave_like 'interactor enabled'
      end

      context "with interactions disabled" do
        before { ::Guard.setup(:no_interactions => true) }

        it_should_behave_like 'interactor disabled'
      end
    end

    context 'with DSL options' do
      before { @enabled = ::Guard::Interactor.enabled }
      after { ::Guard::Interactor.enabled = @enabled }

      context "with interactions enabled" do
        before do
          ::Guard::Interactor.enabled = true
          ::Guard.setup()
        end

        it_should_behave_like 'interactor enabled'
      end

      context "with interactions disabled" do
        before do
          ::Guard::Interactor.enabled = false
          ::Guard.setup()
        end

        it_should_behave_like 'interactor disabled'
      end
    end
  end

  describe '#reload' do
    let(:runner) { stub(:run => true) }
    subject { ::Guard.setup }

    before do
      ::Guard.stub(:runner) { runner }
      ::Guard::Dsl.stub(:reevaluate_guardfile)
      ::Guard.stub(:within_preserved_state).and_yield
      ::Guard::UI.stub(:info)
      ::Guard::UI.stub(:clear)
    end

    it "clear UI" do
      ::Guard::UI.should_receive(:clear)
      subject.reload
    end

    context 'with a old scope format' do
      it 'does not re-evaluate the Guardfile' do
        ::Guard::Dsl.should_not_receive(:reevaluate_guardfile)
        subject.reload({ :group => :frontend })
      end

      it 'reloads Guard' do
        runner.should_receive(:run).with(:reload, { :groups => [:frontend] })
        subject.reload({ :group => :frontend })
      end
    end

    context 'with a new scope format' do
      it 'does not re-evaluate the Guardfile' do
        ::Guard::Dsl.should_not_receive(:reevaluate_guardfile)
        subject.reload({ :groups => [:frontend] })
      end

      it 'reloads Guard' do
        runner.should_receive(:run).with(:reload, { :groups => [:frontend] })
        subject.reload({ :groups => [:frontend] })
      end
    end

    context 'with an empty scope' do
      it 'does re-evaluate the Guardfile' do
        ::Guard::Dsl.should_receive(:reevaluate_guardfile)
        subject.reload
      end

      it 'does not reload Guard' do
        runner.should_not_receive(:run).with(:reload, { })
        subject.reload
      end
    end
  end

  describe ".guards" do
    before(:all) do
      class Guard::FooBar < Guard::Guard;
      end
      class Guard::FooBaz < Guard::Guard;
      end
    end

    after(:all) do
      ::Guard.instance_eval do
        remove_const(:FooBar)
        remove_const(:FooBaz)
      end
    end

    subject do
      guard                   = ::Guard.setup
      @guard_foo_bar_backend  = Guard::FooBar.new([], { :group => 'backend' })
      @guard_foo_bar_frontend = Guard::FooBar.new([], { :group => 'frontend' })
      @guard_foo_baz_backend  = Guard::FooBaz.new([], { :group => 'backend' })
      @guard_foo_baz_frontend = Guard::FooBaz.new([], { :group => 'frontend' })
      guard.instance_variable_get("@guards").push(@guard_foo_bar_backend)
      guard.instance_variable_get("@guards").push(@guard_foo_bar_frontend)
      guard.instance_variable_get("@guards").push(@guard_foo_baz_backend)
      guard.instance_variable_get("@guards").push(@guard_foo_baz_frontend)
      guard
    end

    it "return @guards without any argument" do
      subject.guards.should == subject.instance_variable_get("@guards")
    end

    context "find a guard by as string/symbol" do
      it "find a guard by a string" do
        subject.guards('foo-bar').should == @guard_foo_bar_backend
      end

      it "find a guard by a symbol" do
        subject.guards(:'foo-bar').should == @guard_foo_bar_backend
      end

      it "returns nil if guard is not found" do
        subject.guards('foo-foo').should be_nil
      end
    end

    context "find guards matching a regexp" do
      it "with matches" do
        subject.guards(/^foobar/).should == [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "without matches" do
        subject.guards(/foo$/).should == []
      end
    end

    context "find guards by their group" do
      it "group name is a string" do
        subject.guards(:group => 'backend').should == [@guard_foo_bar_backend, @guard_foo_baz_backend]
      end

      it "group name is a symbol" do
        subject.guards(:group => :frontend).should == [@guard_foo_bar_frontend, @guard_foo_baz_frontend]
      end

      it "returns [] if guard is not found" do
        subject.guards(:group => :unknown).should == []
      end
    end

    context "find guards by their group & name" do
      it "group name is a string" do
        subject.guards(:group => 'backend', :name => 'foo-bar').should == [@guard_foo_bar_backend]
      end

      it "group name is a symbol" do
        subject.guards(:group => :frontend, :name => :'foo-baz').should == [@guard_foo_baz_frontend]
      end

      it "returns [] if guard is not found" do
        subject.guards(:group => :unknown, :name => :'foo-baz').should == []
      end
    end
  end

  describe ".groups" do
    subject do
      guard           = ::Guard.setup
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    context 'without any argument' do
      it "return all groups" do
        subject.groups.should == subject.instance_variable_get("@groups")
      end
    end

    context "find a group by as string/symbol" do
      it "find a group by a string" do
        subject.groups('backend').should == @group_backend
      end

      it "find a group by a symbol" do
        subject.groups(:backend).should == @group_backend
      end

      it "returns nil if group is not found" do
        subject.groups(:foo).should be_nil
      end
    end

    context "find groups matching a regexp" do
      it "with matches" do
        subject.groups(/^back/).should == [@group_backend, @group_backflip]
      end

      it "without matches" do
        subject.groups(/back$/).should == []
      end
    end
  end

  describe ".setup_groups" do
    subject do
      guard           = ::Guard.setup(:guardfile => File.join(@fixture_path, "Guardfile"))
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    it "initializes a default group" do
      subject.setup_groups

      subject.groups.should have(1).item
      subject.groups[0].name.should eq :default
      subject.groups[0].options.should == { }
    end
  end

  describe ".setup_guards" do
    before(:all) {
      class Guard::FooBar < Guard::Guard;
      end }

    after(:all) do
      ::Guard.instance_eval { remove_const(:FooBar) }
    end

    subject do
      guard          = ::Guard.setup(:guardfile => File.join(@fixture_path, "Guardfile"))
      @group_backend = guard.add_guard(:foo_bar)
      guard
    end

    it "return @guards without any argument" do
      subject.guards.should have(1).item

      subject.setup_guards

      subject.guards.should be_empty
    end
  end

  describe ".start" do
    before do
      ::Guard.stub(:setup)
      ::Guard.stub(:listener => mock('listener', :start => true))
      ::Guard.stub(:runner => mock('runner', :run => true))
      ::Guard.stub(:within_preserved_state).and_yield
    end

    it "setup Guard" do
      ::Guard.should_receive(:setup).with(:foo => 'bar')

      ::Guard.start(:foo => 'bar')
    end

    it "displays an info message" do
      ::Guard.instance_variable_set('@watchdir', '/foo/bar')
      ::Guard::UI.should_receive(:info).with("Guard is now watching at '/foo/bar'")

      ::Guard.start
    end

    it "tell the runner to run the :start task" do
      ::Guard.runner.should_receive(:run).with(:start)

      ::Guard.start
    end

    it "start the listener" do
      ::Guard.listener.should_receive(:start)

      ::Guard.start
    end
  end

  describe ".stop" do
    before do
      ::Guard.stub(:setup)
      ::Guard.stub(:listener => mock('listener', :stop => true))
      ::Guard.stub(:runner => mock('runner', :run => true))
      ::Guard.stub(:within_preserved_state).and_yield
    end

    it "turns the notifier off" do
      ::Guard::Notifier.should_receive(:turn_off)

      ::Guard.stop
    end

    it "tell the runner to run the :stop task" do
      ::Guard.runner.should_receive(:run).with(:stop)

      ::Guard.stop
    end

    it "stops the listener" do
      ::Guard.listener.should_receive(:stop)

      ::Guard.stop
    end

    it "sets the running state to false" do
      ::Guard.running = true
      ::Guard.stop
      ::Guard.running.should be_false
    end
  end

  describe ".add_guard" do
    before do
      @guard_rspec_class = double('Guard::RSpec')
      @guard_rspec       = double('Guard::RSpec', :is_a? => true)

      ::Guard.stub!(:get_guard_class) { @guard_rspec_class }

      ::Guard.setup_guards
      ::Guard.setup_groups
      ::Guard.add_group(:backend)
    end

    it "accepts guard name as string" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      ::Guard.add_guard('rspec')
    end

    it "accepts guard name as symbol" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      ::Guard.add_guard(:rspec)
    end

    it "adds guard to the @guards array" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      ::Guard.add_guard(:rspec)

      ::Guard.guards.should eq [@guard_rspec]
    end

    context "with no watchers given" do
      it "gives an empty array of watchers" do
        @guard_rspec_class.should_receive(:new).with([], { }).and_return(@guard_rspec)

        ::Guard.add_guard(:rspec, [])
      end
    end

    context "with watchers given" do
      it "give the watchers array" do
        @guard_rspec_class.should_receive(:new).with([:foo], { }).and_return(@guard_rspec)

        ::Guard.add_guard(:rspec, [:foo])
      end
    end

    context "with no options given" do
      it "gives an empty hash of options" do
        @guard_rspec_class.should_receive(:new).with([], { }).and_return(@guard_rspec)

        ::Guard.add_guard(:rspec, [], [], { })
      end
    end

    context "with options given" do
      it "give the options hash" do
        @guard_rspec_class.should_receive(:new).with([], { :foo => true, :group => :backend }).and_return(@guard_rspec)

        ::Guard.add_guard(:rspec, [], [], { :foo => true, :group => :backend })
      end
    end
  end

  describe ".add_group" do
    before { ::Guard.setup_groups }

    it "accepts group name as string" do
      ::Guard.add_group('backend')

      ::Guard.groups[0].name.should == :default
      ::Guard.groups[1].name.should == :backend
    end

    it "accepts group name as symbol" do
      ::Guard.add_group(:backend)

      ::Guard.groups[0].name.should == :default
      ::Guard.groups[1].name.should == :backend
    end

    it "accepts options" do
      ::Guard.add_group(:backend, { :halt_on_fail => true })

      ::Guard.groups[0].options.should eq({ })
      ::Guard.groups[1].options.should eq({ :halt_on_fail => true })
    end
  end

  describe '.within_preserved_state' do
    subject { ::Guard.setup }
    before { subject.interactor = stub('interactor').as_null_object }

    it 'disallows running the block concurrently to avoid inconsistent states' do
      subject.lock.should_receive(:synchronize)
      subject.within_preserved_state &Proc.new { }
    end

    it 'runs the passed block' do
      @called = false
      subject.within_preserved_state { @called = true }
      @called.should be_true
    end

    context 'with restart interactor enabled' do
      it 'stops the interactor before running the block and starts it again when done' do
        subject.interactor.should_receive(:stop)
        subject.interactor.should_receive(:start)
        subject.within_preserved_state &Proc.new { }
      end
    end

    context 'without restart interactor enabled' do
      it 'stops the interactor before running the block' do
        subject.interactor.should_receive(:stop)
        subject.interactor.should__not_receive(:start)
        subject.within_preserved_state &Proc.new { }
      end
    end
  end

  describe ".get_guard_class" do
    after do
      [:Classname, :DashedClassName, :UnderscoreClassName, :VSpec, :Inline].each do |const|
        Guard.send(:remove_const, const) rescue nil
      end
    end

    it "reports an error if the class is not found" do
      ::Guard::UI.should_receive(:error).twice
      Guard.get_guard_class('notAGuardClass')
    end

    context 'with a nested Guard class' do
      after(:all) { Guard.instance_eval { remove_const(:Classname) } rescue nil }

      it "resolves the Guard class from string" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname;
          end
        }
        Guard.get_guard_class('classname').should == Guard::Classname
      end

      it "resolves the Guard class from symbol" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname;
          end
        }
        Guard.get_guard_class(:classname).should == Guard::Classname
      end
    end

    context 'with a name with dashes' do
      after(:all) { Guard.instance_eval { remove_const(:DashedClassName) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/dashed-class-name'
          class Guard::DashedClassName;
          end
        }
        Guard.get_guard_class('dashed-class-name').should == Guard::DashedClassName
      end
    end

    context 'with a name with underscores' do
      after(:all) { Guard.instance_eval { remove_const(:UnderscoreClassName) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/underscore_class_name'
          class Guard::UnderscoreClassName;
          end
        }
        Guard.get_guard_class('underscore_class_name').should == Guard::UnderscoreClassName
      end
    end

    context 'with a name where its class does not follow the strict case rules' do
      after(:all) { Guard.instance_eval { remove_const(:VSpec) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/vspec'
          class Guard::VSpec;
          end
        }
        Guard.get_guard_class('vspec').should == Guard::VSpec
      end
    end

    context 'with an inline Guard class' do
      after(:all) { Guard.instance_eval { remove_const(:Inline) } rescue nil }

      it 'returns the Guard class' do
        module Guard
          class Inline < Guard
          end
        end

        Guard.should_not_receive(:require)
        Guard.get_guard_class('inline').should == Guard::Inline
      end
    end

    context 'when set to fail gracefully' do
      it 'does not print error messages on fail' do
        ::Guard::UI.should_not_receive(:error)
        Guard.get_guard_class('notAGuardClass', true).should be_nil
      end
    end
  end

  describe ".locate_guard" do
    it "returns the path of a Guard gem" do
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        gem_location = Gem::Specification.find_by_name("guard-rspec").full_gem_path
      else
        gem_location = Gem.source_index.find_name("guard-rspec").last.full_gem_path
      end

      Guard.locate_guard('rspec').should == gem_location
    end
  end

  describe ".guard_gem_names" do
    it "returns the list of guard gems" do
      gems = Guard.guard_gem_names
      gems.should include("rspec")
    end

    it "returns the list of embedded guard gems" do
      gem1 = stub(:gem, :name => "gem1", :full_gem_path => '/gem1' )
      gem2 = stub(:gem, :name => "gem2", :full_gem_path => '/gem2' )
      gem3 = stub(:gem, :name => "guard", :full_gem_path => '/guard' )

      File.should_receive(:exists?).with('/gem1/lib/guard/gem1.rb').and_return(false)
      File.should_receive(:exists?).with('/gem2/lib/guard/gem2.rb').and_return(true)

      Gem::Specification.should_receive(:find_all).and_return([gem1, gem2, gem3])

      Guard.guard_gem_names.should == ['gem2']
    end

  end

  describe ".debug_command_execution" do
    subject { ::Guard.setup }

    before do
      Guard.unstub(:debug_command_execution)
      @original_system  = Kernel.method(:system)
      @original_command = Kernel.method(:"`")
    end

    after do
      Kernel.send(:remove_method, :system, :'`')
      Kernel.send(:define_method, :system, @original_system.to_proc)
      Kernel.send(:define_method, :"`", @original_command.to_proc)
      Guard.stub(:debug_command_execution)
    end

    it "outputs Kernel.#system method parameters" do
      ::Guard::UI.should_receive(:debug).with("Command execution: exit 0")
      ::Guard.setup(:debug => true)
      system("exit", "0").should be_false
    end

    it "outputs Kernel.#` method parameters" do
      ::Guard::UI.should_receive(:debug).with("Command execution: echo test")
      ::Guard.setup(:debug => true)
      `echo test`.should == "test\n"
    end

    it "outputs %x{} method parameters" do
      ::Guard::UI.should_receive(:debug).with("Command execution: echo test")
      ::Guard.setup(:debug => true)
      %x{echo test}.should == "test\n"
    end

  end

  describe ".deprecated_options_warning" do
    subject { ::Guard.setup }

    context "with watch_all_modifications options" do
      before { subject.options[:watch_all_modifications] = true }

      it 'displays a deprecation warning to the user' do
        ::Guard::UI.should_receive(:deprecation)
        subject.deprecated_options_warning
      end
    end

    context "with no_vendor options" do
      before { subject.options[:no_vendor] = true }

      it 'displays a deprecation warning to the user' do
        ::Guard::UI.should_receive(:deprecation)
        subject.deprecated_options_warning
      end
    end

  end

end
