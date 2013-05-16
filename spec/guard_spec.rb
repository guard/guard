require 'spec_helper'
require 'guard/plugin'

describe Guard do
  describe '.reload' do
    let(:runner) { stub(:run => true) }
    let(:group) { ::Guard::Group.new('frontend') }
    subject { ::Guard.setup }

    before do
      ::Guard.stub(:runner) { runner }
      ::Guard.stub(:within_preserved_state).and_yield
      ::Guard::UI.stub(:info)
      ::Guard::UI.stub(:clear)
    end

    it 'clears the screen' do
      ::Guard::UI.should_receive(:clear)

      subject.reload
    end

    context 'with a given scope' do
      it 'does not re-evaluate the Guardfile' do
        Guard::Guardfile::Evaluator.any_instance.should_not_receive(:reevaluate_guardfile)

        subject.reload({ :groups => [group] })
      end

      it 'reloads Guard' do
        runner.should_receive(:run).with(:reload, { :groups => [group] })

        subject.reload({ :groups => [group] })
      end
    end

    context 'with an empty scope' do
      it 'does re-evaluate the Guardfile' do
        ::Guard::Guardfile::Evaluator.any_instance.should_receive(:reevaluate_guardfile)

        subject.reload
      end

      it 'does not reload Guard' do
        runner.should_not_receive(:run).with(:reload, {})

        subject.reload
      end
    end
  end

  describe '.guards' do
    before do
      stub_const 'Guard::FooBar', Class.new(Guard::Plugin)
      stub_const 'Guard::FooBaz', Class.new(Guard::Plugin)
      @guard_foo_bar_backend = described_class.add_guard('foo_bar', :group => 'backend')
      @guard_foo_baz_backend = described_class.add_guard('foo_baz', :group => 'backend')
      @guard_foo_bar_frontend = described_class.add_guard('foo_bar', :group => 'frontend')
      @guard_foo_baz_frontend = described_class.add_guard('foo_baz', :group => 'frontend')
    end

    it "return @guards without any argument" do
      described_class.guards.should eq subject.instance_variable_get("@guards")
    end

    context "find a guard by as string/symbol" do
      it "find a guard by a string" do
        described_class.guards('foo-bar').should eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "find a guard by a symbol" do
        described_class.guards(:'foo-bar').should eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "returns nil if guard is not found" do
        described_class.guards('foo-foo').should eq nil
      end
    end

    context "find guards matching a regexp" do
      it "with matches" do
        described_class.guards(/^foobar/).should eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "without matches" do
        described_class.guards(/foo$/).should eq nil
      end
    end

    context "find guards by their group" do
      it "group name is a string" do
        described_class.guards(:group => 'backend').should eq [@guard_foo_bar_backend, @guard_foo_baz_backend]
      end

      it "group name is a symbol" do
        described_class.guards(:group => :frontend).should eq [@guard_foo_bar_frontend, @guard_foo_baz_frontend]
      end

      it "returns nil if guard is not found" do
        described_class.guards(:group => :unknown).should eq nil
      end
    end

    context "find guards by their group & name" do
      it "group name is a string" do
        described_class.guards(:group => 'backend', :name => 'foo-bar').should eq @guard_foo_bar_backend
      end

      it "group name is a symbol" do
        described_class.guards(:group => :frontend, :name => :'foo-baz').should eq @guard_foo_baz_frontend
      end

      it "returns nil if guard is not found" do
        described_class.guards(:group => :unknown, :name => :'foo-baz').should eq nil
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

    context 'without no argument' do
      it 'returns all groups' do
        subject.groups.should eq subject.instance_variable_get("@groups")
      end
    end

    context 'with a string argument' do
      it 'returns a single group' do
        subject.groups('backend').should eq @group_backend
      end
    end

    context 'with a symbol argument matching a group' do
      it 'returns a single group' do
        subject.groups(:backend).should eq @group_backend
      end
    end

    context 'with a symbol argument not matching a group' do
      it 'returns nil' do
        subject.groups(:foo).should eq nil
      end
    end

    context 'with a regexp argument matching a group' do
      it 'returns an array of groups' do
        subject.groups(/^back/).should eq [@group_backend, @group_backflip]
      end
    end

    context 'with a regexp argument not matching a group' do
      it 'returns nil' do
        subject.groups(/back$/).should eq nil
      end
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

  describe '.add_guard' do
    let(:plugin_util) { double('Guard::PluginUtil') }
    let(:guard_rspec) { double('Guard::RSpec instance') }

    before do
      ::Guard::PluginUtil.should_receive(:new).with('rspec') { plugin_util }
      plugin_util.stub!(:initialize_plugin) { guard_rspec }

      ::Guard.reset_guards
    end

    it 'delegates the plugin instantiation to Guard::PluginUtil' do
      plugin_util.should_receive(:initialize_plugin).with(:watchers => ['watcher'], :group => 'foo')

      ::Guard.add_guard('rspec', :watchers => ['watcher'], :group => 'foo')
    end

    it "adds guard to the @guards array" do
      ::Guard.add_guard('rspec')

      ::Guard.guards.should eq [guard_rspec]
    end
  end

  describe '.add_group' do
    before { ::Guard.reset_groups }

    it "accepts group name as string" do
      ::Guard.add_group('backend')
      ::Guard.groups[0].name.should eq :default
      ::Guard.groups[1].name.should eq :backend
    end

    it "accepts group name as symbol" do
      ::Guard.add_group(:backend)

      ::Guard.groups[0].name.should eq :default
      ::Guard.groups[1].name.should eq :backend
    end

    it "accepts options" do
      ::Guard.add_group(:backend, { :halt_on_fail => true })

      ::Guard.groups[0].options.should eq({})
      ::Guard.groups[1].options.should eq({ :halt_on_fail => true })
    end
  end

  describe '.within_preserved_state' do
    subject { ::Guard.setup }
    before { subject.interactor = stub('interactor').as_null_object }

    it 'disallows running the block concurrently to avoid inconsistent states' do
      subject.lock.should_receive(:synchronize)
      subject.within_preserved_state &Proc.new {}
    end

    it 'runs the passed block' do
      @called = false
      subject.within_preserved_state { @called = true }
      @called.should be_true
    end

    context '@running is true' do
      it 'stops the interactor before running the block and starts it again when done' do
        subject.interactor.should_receive(:stop)
        subject.interactor.should_receive(:start)
        subject.within_preserved_state &Proc.new {}
      end
    end

    context '@running is false' do
      before { ::Guard.stub(:running) { false } }

      it 'stops the interactor before running the block and do not starts it again when done' do
        subject.interactor.should_receive(:stop)
        subject.interactor.should_not_receive(:start)
        subject.within_preserved_state &Proc.new {}
      end
    end
  end

  describe '.get_guard_class' do
    let(:plugin_util) { stub('Guard::PluginUtil', plugin_class: true) }
    before { ::Guard::PluginUtil.stub(:new).and_return(plugin_util) }

    it 'displays a deprecation warning to the user' do
      ::Guard::UI.should_receive(:deprecation).with(::Guard::Deprecator::GET_GUARD_CLASS_DEPRECATION)

      described_class.get_guard_class('rspec')
    end

    it 'delegates to Guard::PluginUtil' do
      ::Guard::PluginUtil.should_receive(:new).with('rspec') { plugin_util }
      plugin_util.should_receive(:plugin_class).with(:fail_gracefully => false)

      described_class.get_guard_class('rspec')
    end

    describe ':fail_gracefully' do
      it 'pass it to get_guard_class' do
        ::Guard::PluginUtil.should_receive(:new).with('rspec') { plugin_util }
        plugin_util.should_receive(:plugin_class).with(:fail_gracefully => true)

        described_class.get_guard_class('rspec', true)
      end
    end
  end

  describe '.locate_guard' do
    let(:plugin_util) { stub('Guard::PluginUtil', plugin_location: true) }
    before { ::Guard::PluginUtil.stub(:new).and_return(plugin_util) }

    it 'displays a deprecation warning to the user' do
      ::Guard::UI.should_receive(:deprecation).with(::Guard::Deprecator::LOCATE_GUARD_DEPRECATION)

      described_class.locate_guard('rspec')
    end

    it 'delegates to Guard::PluginUtil' do
      ::Guard::PluginUtil.should_receive(:new).with('rspec') { plugin_util }
      plugin_util.should_receive(:plugin_location)

      described_class.locate_guard('rspec')
    end
  end

  describe '.guard_gem_names' do
    before { ::Guard::PluginUtil.stub(:plugin_names) }

    it 'displays a deprecation warning to the user' do
      ::Guard::UI.should_receive(:deprecation).with(::Guard::Deprecator::GUARD_GEM_NAMES_DEPRECATION)

      described_class.guard_gem_names
    end

    it 'delegates to Guard::PluginUtil' do
      Guard::PluginUtil.should_receive(:plugin_names)

      described_class.guard_gem_names
    end
  end

end
