require 'spec_helper'
require 'guard/plugin'

describe Guard::Setuper do

  let(:guardfile_evaluator) { double('Guard::Guardfile::Evaluator instance') }

  before do
    Guard::Interactor.stub(:fabricate)
    Dir.stub(:chdir)
  end

  describe '.setup' do
    let(:options) { { :my_opts => true, :guardfile => File.join(@fixture_path, "Guardfile") } }
    subject { Guard.setup(options) }

    it "returns itself for chaining" do
      subject.should be Guard
    end

    it "initializes the plugins" do
      subject.guards.should eq []
    end

    it "initializes the groups" do
      subject.groups[0].name.should eq :default
      subject.groups[0].options.should eq({})
    end

    it "initializes the options" do
      subject.options.should include(:my_opts)
    end

    it "initializes the listener" do
      subject.listener.should be_kind_of(Listen::Listener)
    end

    it "respect the watchdir option" do
      Guard.setup(:watchdir => '/usr')

      Guard.listener.directories.should eq ['/usr']
    end

    it "changes the current work dir to the watchdir" do
      Dir.should_receive(:chdir).with('/tmp')

      Guard.setup(:watchdir => '/tmp')
    end

    it 'call setup_signal_traps' do
      Guard.should_receive(:setup_signal_traps)
      subject
    end

    it 'create the evaluator and evaluate the Guardfile' do
      Guard::Guardfile::Evaluator.should_receive(:new).with(options)
      Guard.should_receive(:evaluate_guardfile)

      subject
    end

    it 'displays an error message when no guard are defined in Guardfile' do
      Guard::UI.should_receive(:error).with('No guards found in Guardfile, please add at least one.')

      subject
    end

    it 'call setup_notifier' do
      Guard.should_receive(:setup_notifier)
      subject
    end

    it 'call setup_interactor' do
      Guard.should_receive(:setup_interactor)
      subject
    end

    it 'show the deprecations' do
      Guard::Deprecator.should_receive(:deprecated_options_warning)
      Guard::Deprecator.should_receive(:deprecated_plugin_methods_warning)

      subject
    end

    context 'without the group or plugin option' do
      it "initializes the empty scope" do
        subject.scope.should eq({ :groups => [], :plugins => [] })
      end
    end

    context 'with the group option' do
      let(:options) { {
        :group              => %w[backend frontend],
        :guardfile_contents => "group :backend do; end; group :frontend do; end; group :excluded do; end"
      } }

      it 'initializes the group scope' do
        subject.scope[:plugins].should be_empty
        subject.scope[:groups].count.should be 2
        subject.scope[:groups][0].name.should eq :backend
        subject.scope[:groups][1].name.should eq :frontend
      end
    end

    context 'with the plugin option' do
      let(:options) do
        {
          :plugin             => ['cucumber', 'jasmine'],
          :guardfile_contents => "guard :jasmine do; end; guard :cucumber do; end; guard :coffeescript do; end"
        }
      end

      before do
        stub_const 'Guard::Jasmine', Class.new(Guard::Plugin)
        stub_const 'Guard::Cucumber', Class.new(Guard::Plugin)
        stub_const 'Guard::CoffeeScript', Class.new(Guard::Plugin)
      end

      it "initializes the plugin scope" do
        subject.scope[:groups].should be_empty
        subject.scope[:plugins].count.should be 2
        subject.scope[:plugins][0].class.should eq ::Guard::Cucumber
        subject.scope[:plugins][1].class.should eq ::Guard::Jasmine
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
        ::Guard::UI.options[:level].should eq :debug
      end
    end
  end

  describe '.setup_signal_traps', :speed => 'slow' do
    before { ::Guard::Dsl.stub(:evaluate_guardfile) }
  describe '.evaluate_guardfile' do
    it 'evaluates the Guardfile' do
      Guard.stub(:evaluator) { guardfile_evaluator }
      guardfile_evaluator.should_receive(:evaluate_guardfile)

      Guard.evaluate_guardfile
    end
  end


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
          before { Guard.listener.should_receive(:paused?).and_return true }

          it 'un-pause Guard' do
            Guard.should_receive(:pause)
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
          before { Guard.should_receive(:interactor).and_return nil }

          it 'stops Guard' do
            Guard.should_receive(:stop)
            Process.kill :INT, Process.pid
            sleep 1
          end
        end

        context 'with an interactor' do
          let(:interactor) { mock('interactor', :thread => mock('thread')) }
          before { Guard.should_receive(:interactor).exactly(3).times.and_return(interactor) }

          it 'delegates to the Pry thread' do
            Guard.interactor.thread.should_receive(:raise).with Interrupt
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

  describe '.setup_listener' do
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

  describe '.setup_notifier' do
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

  describe '.setup_interactor' do
    context 'with CLI options' do
      before do
        @enabled                  = Guard::Interactor.enabled
        Guard::Interactor.enabled = true
      end

      after { Guard::Interactor.enabled = @enabled }

      context 'with interactions enabled' do
        before { Guard.setup(:no_interactions => false) }

        it_should_behave_like 'interactor enabled'
      end

      context "with interactions disabled" do
        before { Guard.setup(:no_interactions => true) }

        it_should_behave_like 'interactor disabled'
      end
    end

    context 'with DSL options' do
      before { @enabled = Guard::Interactor.enabled }
      after { Guard::Interactor.enabled = @enabled }

      context "with interactions enabled" do
        before do
          Guard::Interactor.enabled = true
          Guard.setup
        end

        it_should_behave_like 'interactor enabled'
      end

      context "with interactions disabled" do
        before do
          Guard::Interactor.enabled = false
          Guard.setup
        end

        it_should_behave_like 'interactor disabled'
      end
    end
  end

  describe '.reset_groups' do
    subject do
      guard           = Guard.setup(:guardfile => File.join(@fixture_path, "Guardfile"))
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    it "initializes a default group" do
      subject.reset_groups

      subject.groups.should have(1).item
      subject.groups[0].name.should eq :default
      subject.groups[0].options.should eq({})
    end
  end

  describe '.reset_guards' do
    before { class Guard::FooBar < Guard::Plugin; end }
    subject do
      ::Guard.setup(:guardfile => File.join(@fixture_path, "Guardfile")).tap { |g| g.add_guard(:foo_bar) }
    end
    after do
      ::Guard.instance_eval { remove_const(:FooBar) }
    end

    it "return clear the guards array" do
      subject.guards.should have(1).item

      subject.reset_guards

      subject.guards.should be_empty
    end
  end

end
