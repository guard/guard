require 'spec_helper'

describe Guard do

  describe ".setup" do
    let(:options) { { :my_opts => true, :guardfile => File.join(@fixture_path, "Guardfile") } }
    subject { described_class.setup(options) }

    it "returns itself for chaining" do
      subject.should be ::Guard
    end

    it "initializes @guards" do
      subject.guards.should eq []
    end

    it "initializes @groups" do
      subject.groups[0].name.should eq :default
      subject.groups[0].options.should == {}
    end

    it "initializes the options" do
      subject.options.should include(:my_opts)
    end

    it "initializes the listener" do
      subject.listener.should be_kind_of(Listen::Listener)
    end

    it "respect the watchdir option" do
      described_class.setup(:watchdir => '/usr')

      described_class.listener.directory.should eq '/usr'
    end

    it "logs command execution if the debug option is true" do
      described_class.should_receive(:debug_command_execution)

      described_class.setup(:debug => true)
    end

    it "call setup_signal_traps" do
      described_class.should_receive(:setup_signal_traps)
      subject
    end

    it "evaluates the DSL" do
      described_class::Dsl.should_receive(:evaluate_guardfile).with(options)
      subject
    end

    it "displays an error message when no guard are defined in Guardfile" do
      described_class::UI.should_receive(:error)
      subject
    end

    it "call setup_notifier" do
      described_class.should_receive(:setup_notifier)
      subject
    end

    it "call setup_interactor" do
      described_class.should_receive(:setup_interactor)
      subject
    end
  end

  describe ".setup_signal_traps" do
    unless windows?
      context 'when receiving SIGUSR1' do
        context 'when Guard is running' do
          before { described_class.listener.should_receive(:paused?).and_return false }

          it 'pauses Guard' do
            described_class.should_receive(:pause)
            Process.kill :USR1, Process.pid
            sleep 1
          end
        end

        context 'when Guard is already paused' do
          before { described_class.listener.should_receive(:paused?).and_return true }

          it 'does not pauses Guard' do
            described_class.should_not_receive(:pause)
            Process.kill :USR1, Process.pid
            sleep 1
          end
        end
      end

      context 'when receiving SIGUSR2' do
        context 'when Guard is paused' do
          before { described_class.listener.should_receive(:paused?).and_return true }

          it 'un-pause Guard' do
            described_class.should_receive(:pause)
            Process.kill :USR2, Process.pid
            sleep 1
          end
        end

        context 'when Guard is already running' do
          before { described_class.listener.should_receive(:paused?).and_return false }

          it 'does not un-pause Guard' do
            described_class.should_not_receive(:pause)
            Process.kill :USR2, Process.pid
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
      before { described_class.stub(:options).and_return("latency" => 1.5) }

      it "pass option to listener" do
        Listen.should_receive(:to).with(an_instance_of(String), { :relative_paths => true, :latency => 1.5 }) { listener }
        ::Guard.setup_listener
      end
    end

    context "with force_polling option" do
      before { described_class.stub(:options).and_return("force_polling" => true) }

      it "pass option to listener" do
        Listen.should_receive(:to).with(an_instance_of(String), { :relative_paths => true, :force_polling => true }) { listener }
        ::Guard.setup_listener
      end
    end
  end

  describe ".setup_notifier" do
    context "with the notify option enabled" do
      before { described_class.stub(:options).and_return(:notify => true) }

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
        described_class.stub(:options).and_return(:notify => false)
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
    context "with interactions enabled" do
      before { described_class.setup(:no_interactions => false) }

      it_should_behave_like 'interactor enabled'
    end

    context "with interactions disabled" do
      before { described_class.setup(:no_interactions => true) }

      it_should_behave_like 'interactor disabled'
    end
  end

  describe '#reload' do
    let(:runner) { stub(:run => true) }

    before do
      ::Guard.stub(:runner) { runner }
      ::Guard::Dsl.stub(:reevaluate_guardfile)
      ::Guard::UI.stub(:info)
      ::Guard::UI.stub(:clear)
    end

    it "clear UI" do
      ::Guard::UI.should_receive(:clear)
      subject.reload({ })
    end

    context 'with a scope' do
      it 'does not re-evaluate the Guardfile' do
        ::Guard::Dsl.should_not_receive(:reevaluate_guardfile)
        subject.reload({ :group => :frontend })
      end

      it 'reloads Guard' do
        ::Guard.should_receive(:reload).with({ :group => :frontend })
        subject.reload({ :group => :frontend })
      end
    end

    context 'with an empty scope' do
      it 'does re-evaluate the Guardfile' do
        ::Guard::Dsl.should_receive(:reevaluate_guardfile)
        subject.reload({ })
      end

      it 'reloads Guard' do
        ::Guard.should_receive(:reload).with({ })
        subject.reload({ })
      end
    end
  end

  describe ".guards" do
    before(:all) do
      class Guard::FooBar < Guard::Guard; end
      class Guard::FooBaz < Guard::Guard; end
    end

    after(:all) do
      ::Guard.instance_eval do
        remove_const(:FooBar)
        remove_const(:FooBaz)
      end
    end

    subject do
      guard = ::Guard.setup
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

    describe "find a guard by as string/symbol" do
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

    describe "find guards matching a regexp" do
      it "with matches" do
        subject.guards(/^foobar/).should == [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "without matches" do
        subject.guards(/foo$/).should == []
      end
    end

    describe "find guards by their group" do
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

    describe "find guards by their group & name" do
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
      guard = ::Guard.setup
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    it "return @groups without any argument" do
      subject.groups.should == subject.instance_variable_get("@groups")
    end

    describe "find a group by as string/symbol" do
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

    describe "find groups matching a regexp" do
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
      guard = ::Guard.setup(:guardfile => File.join(@fixture_path, "Guardfile"))
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    it "return @groups without any argument" do
      subject.groups.should have(3).items

      subject.setup_groups

      subject.groups.should have(1).item
      subject.groups[0].name.should eq :default
      subject.groups[0].options.should == {}
    end
  end

  describe ".setup_guards" do
    before(:all) { class Guard::FooBar < Guard::Guard; end }

    after(:all) do
      ::Guard.instance_eval { remove_const(:FooBar) }
    end

    subject do
      guard = ::Guard.setup(:guardfile => File.join(@fixture_path, "Guardfile"))
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
      described_class.stub(:setup)
      described_class.stub(:interactor => mock('interactor', :start => true))
      described_class.stub(:listener => mock('listener', :start => true))
      described_class.stub(:runner => mock('runner', :run => true))
    end

    it "setup Guard" do
      described_class.should_receive(:setup).with(:foo => 'bar')

      described_class.start(:foo => 'bar')
    end

    it "displays an info message" do
      described_class.instance_variable_set('@watchdir', '/foo/bar')
      described_class::UI.should_receive(:info).with("Guard is now watching at '/foo/bar'")

      described_class.start
    end

    it "tells the interactor to start" do
      described_class.interactor.should_receive(:start)

      described_class.start
    end

    it "tell the runner to run the :start task" do
      described_class.runner.should_receive(:run).with(:start)

      described_class.start
    end

    it "start the listener" do
      described_class.listener.should_receive(:start)

      described_class.start
    end
  end

  describe ".add_guard" do
    before do
      @guard_rspec_class = double('Guard::RSpec')
      @guard_rspec = double('Guard::RSpec', :is_a? => true)

      described_class.stub!(:get_guard_class) { @guard_rspec_class }

      described_class.setup_guards
      described_class.setup_groups
      described_class.add_group(:backend)
    end

    it "accepts guard name as string" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      described_class.add_guard('rspec')
    end

    it "accepts guard name as symbol" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      described_class.add_guard(:rspec)
    end

    it "adds guard to the @guards array" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      described_class.add_guard(:rspec)

      described_class.guards.should eq [@guard_rspec]
    end

    context "with no watchers given" do
      it "gives an empty array of watchers" do
        @guard_rspec_class.should_receive(:new).with([], {}).and_return(@guard_rspec)

        described_class.add_guard(:rspec, [])
      end
    end

    context "with watchers given" do
      it "give the watchers array" do
        @guard_rspec_class.should_receive(:new).with([:foo], {}).and_return(@guard_rspec)

        described_class.add_guard(:rspec, [:foo])
      end
    end

    context "with no options given" do
      it "gives an empty hash of options" do
        @guard_rspec_class.should_receive(:new).with([], {}).and_return(@guard_rspec)

        described_class.add_guard(:rspec, [], [], {})
      end
    end

    context "with options given" do
      it "give the options hash" do
        @guard_rspec_class.should_receive(:new).with([], { :foo => true, :group => :backend }).and_return(@guard_rspec)

        described_class.add_guard(:rspec, [], [], { :foo => true, :group => :backend })
      end
    end
  end

  describe ".add_group" do
    before { described_class.setup_groups }

    it "accepts group name as string" do
      described_class.add_group('backend')

      described_class.groups[0].name.should == :default
      described_class.groups[1].name.should == :backend
    end

    it "accepts group name as symbol" do
      described_class.add_group(:backend)

      described_class.groups[0].name.should == :default
      described_class.groups[1].name.should == :backend
    end

    it "accepts options" do
      described_class.add_group(:backend, { :halt_on_fail => true })

      described_class.groups[0].options.should eq({})
      described_class.groups[1].options.should eq({ :halt_on_fail => true })
    end
  end

  describe '.within_preserved_state' do
    subject { ::Guard.setup }

    it 'disables the interactor before running the block and then re-enables it when done' do
      subject.interactor.should_receive(:stop)
      subject.interactor.should_receive(:start)
      subject.within_preserved_state &Proc.new {}
    end

    it 'disallows running the block concurrently to avoid inconsistent states' do
      subject.lock.should_receive(:synchronize)
      subject.within_preserved_state &Proc.new {}
    end

    it 'runs the passed block' do
      @called = false
      subject.within_preserved_state { @called = true }
      @called.should be_true
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
          class Guard::Classname; end
        }
        Guard.get_guard_class('classname').should == Guard::Classname
      end

      it "resolves the Guard class from symbol" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname; end
        }
        Guard.get_guard_class(:classname).should == Guard::Classname
      end
    end

    context 'with a name with dashes' do
      after(:all) { Guard.instance_eval { remove_const(:DashedClassName) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/dashed-class-name'
          class Guard::DashedClassName; end
        }
        Guard.get_guard_class('dashed-class-name').should == Guard::DashedClassName
      end
    end

    context 'with a name with underscores' do
      after(:all) { Guard.instance_eval { remove_const(:UnderscoreClassName) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/underscore_class_name'
          class Guard::UnderscoreClassName; end
        }
        Guard.get_guard_class('underscore_class_name').should == Guard::UnderscoreClassName
      end
    end

    context 'with a name where its class does not follow the strict case rules' do
      after(:all) { Guard.instance_eval { remove_const(:VSpec) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/vspec'
          class Guard::VSpec; end
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
  end

  describe ".debug_command_execution" do
    subject { ::Guard.setup }

    before do
      @original_system = Kernel.method(:system)
      @original_command = Kernel.method(:"`")
    end

    after do
      Kernel.send(:remove_method, :system, :'`')
      Kernel.send(:define_method, :system, @original_system.to_proc)
      Kernel.send(:define_method, :"`", @original_command.to_proc)
    end

    it "outputs Kernel.#system method parameters" do
      ::Guard.setup(:debug => true)
      ::Guard::UI.should_receive(:debug).with("Command execution: exit 0")
      system("exit", "0").should be_false
    end

    it "outputs Kernel.#` method parameters" do
      ::Guard.setup(:debug => true)
      ::Guard::UI.should_receive(:debug).twice.with("Command execution: echo test")
      `echo test`.should == "test\n"
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
