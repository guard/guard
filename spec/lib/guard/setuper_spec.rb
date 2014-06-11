require 'spec_helper'
require 'guard/plugin'

describe Guard::Setuper do

  let(:guardfile_evaluator) { instance_double(Guard::Guardfile::Evaluator) }

  before do
    Guard::Interactor.enabled = true
    allow(Dir).to receive(:chdir)
  end

  describe '.setup' do
    subject { Guard.setup(options) }

    let(:options) do
      {
        my_opts: true,
        guardfile: File.join(@fixture_path, 'Guardfile')
      }
    end

    let(:listener) { instance_double(Listen::Listener) }

    before do
      allow(Listen).to receive(:to).with(Dir.pwd, {}) { listener }
      allow(Guard::Notifier).to receive(:turn_on)
    end

    it 'returns itself for chaining' do
      expect(subject).to be Guard
    end

    it 'initializes the plugins' do
      expect(subject.plugins).to eq []
    end

    it 'initializes the groups' do
      expect(subject.groups[0].name).to eq :default
      expect(subject.groups[0].options).to eq({})
    end

    it 'lazily initializes the options' do
      expect(subject.options[:my_opts]).to be_truthy
    end

    it 'lazily initializes the evaluator' do
      expect(subject.evaluator).to be_kind_of(Guard::Guardfile::Evaluator)
    end

    it 'initializes the listener' do
      expect(subject.listener).to be(listener)
    end

    it 'respect the watchdir option' do
      if Guard::WINDOWS
        expect(Listen).to receive(:to).
          with('C:/usr', {}) { listener }
      else
        expect(Listen).to receive(:to).
          with('/usr', {}) { listener }
      end

      Guard.setup(watchdir: '/usr')
    end

    it 'respect the watchdir option with multiple directories' do
      if Guard::WINDOWS
        expect(Listen).to receive(:to).
          with('C:/usr', 'C:/bin', {}) { listener }
      else
        expect(Listen).to receive(:to).
          with('/usr', '/bin', {}) { listener }
      end

      ::Guard.setup(watchdir: ['/usr', '/bin'])
    end

    it 'call setup_signal_traps' do
      expect(Guard).to receive(:_setup_signal_traps)

      subject
    end

    it 'evaluates the Guardfile' do
      expect(Guard).to receive(:evaluate_guardfile)

      subject
    end

    it 'displays an error message when no guard are defined in Guardfile' do
      expect(Guard::UI).to receive(:error).
        with('No plugins found in Guardfile, please add at least one.')

      subject
    end

    it 'call setup_notifier' do
      expect(Guard).to receive(:_setup_notifier)

      subject
    end

    context 'without the group or plugin option' do
      it 'initializes the empty scope' do
        expect(subject.scope).to eq(groups: [], plugins: [])
      end
    end

    context 'with the group option' do
      let(:options) do
        {
          group:              %w(backend frontend),
          guardfile_contents: 'group :backend do; end; '\
          'group :frontend do; end; group :excluded do; end'
        }
      end

      it 'initializes the group scope' do
        expect(subject.scope[:plugins]).to be_empty
        expect(subject.scope[:groups].count).to be 2
        expect(subject.scope[:groups][0].name).to eq :backend
        expect(subject.scope[:groups][1].name).to eq :frontend
      end
    end

    context 'with the plugin option' do
      let(:options) do
        {
          plugin:             %w(cucumber jasmine),
          guardfile_contents: 'guard :jasmine do; end; '\
            'guard :cucumber do; end; guard :coffeescript do; end'
        }
      end

      before do
        stub_const 'Guard::Jasmine', Class.new(Guard::Plugin)
        stub_const 'Guard::Cucumber', Class.new(Guard::Plugin)
        stub_const 'Guard::CoffeeScript', Class.new(Guard::Plugin)
      end

      it 'initializes the plugin scope' do
        expect(subject.scope[:groups]).to be_empty
        expect(subject.scope[:plugins].count).to be 2
        expect(subject.scope[:plugins][0].class).to eq ::Guard::Cucumber
        expect(subject.scope[:plugins][1].class).to eq ::Guard::Jasmine
      end
    end

    context 'with the debug mode turned on' do
      let(:options) do
        {
          debug: true,
          guardfile: File.join(@fixture_path, 'Guardfile')
        }
      end

      before do
        allow(Guard).to receive(:_debug_command_execution)
      end

      it 'logs command execution if the debug option is true' do
        expect(::Guard).to receive(:_debug_command_execution)
        subject
      end

      it 'sets the log level to :debug if the debug option is true' do
        subject
        expect(::Guard::UI.options[:level]).to eq :debug
      end
    end

    context 'with latency option' do
      let(:options) { { latency: 1.5 }}

      it 'passes option to listener' do
        expect(Listen).to receive(:to).
          with(anything,  latency: 1.5) { listener }
        subject
      end
    end

    context 'with force_polling option' do
      let(:options) { { force_polling: true } }

      it 'pass option to listener' do
        expect(Listen).to receive(:to).
          with(anything, force_polling: true) { listener }
        subject
      end
    end
  end

  describe '.reset_groups' do
    subject do
      allow(Listen).to receive(:to).with(Dir.pwd, {})
      allow(Guard::Notifier).to receive(:turn_on)

      guard = Guard.setup(guardfile: File.join(@fixture_path, 'Guardfile'))

      @group_backend = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    it 'initializes a default group' do
      subject.reset_groups

      expect(subject.groups.size).to eq 1
      expect(subject.groups[0].name).to eq :default
      expect(subject.groups[0].options).to eq({})
    end
  end

  describe '.reset_plugins' do
    before do
      allow(Listen).to receive(:to).with(Dir.pwd, {})
      allow(Guard::Notifier).to receive(:turn_on)

      Guard.setup
      module Guard
        class FooBar < Guard::Plugin; end
      end
    end

    subject do
      path = File.join(@fixture_path, 'Guardfile')
      ::Guard.setup(guardfile: path).tap { |g| g.add_plugin(:foo_bar) }
    end

    after do
      ::Guard.instance_eval { remove_const(:FooBar) }
    end

    it 'return clear the plugins array' do
      expect(subject.plugins.size).to eq 1

      subject.reset_plugins

      expect(subject.plugins).to be_empty
    end
  end

  describe '.evaluate_guardfile' do
    it 'evaluates the Guardfile' do
      allow(Guard).to receive(:evaluator) { guardfile_evaluator }
      expect(guardfile_evaluator).to receive(:evaluate_guardfile)

      Guard.evaluate_guardfile
    end
  end

  describe '._setup_signal_traps', speed: 'slow' do
    before do
      allow(::Guard).to receive(:evaluate_guardfile)
      allow(Listen).to receive(:to).with(Dir.pwd, {})
      allow(Guard::Notifier).to receive(:turn_on)
      ::Guard.setup
    end

    unless windows? || defined?(JRUBY_VERSION)
      context 'when receiving SIGUSR1' do
        it 'pauses Guard' do
          expect(::Guard).to receive(:async_queue_add).
            with([:guard_pause, :paused])

          Process.kill :USR1, Process.pid
          sleep 1
        end
      end

      context 'when receiving SIGUSR2' do
        it 'un-pause Guard' do
          expect(Guard).to receive(:async_queue_add).
            with([:guard_pause, :unpaused])

          Process.kill :USR2, Process.pid
          sleep 1
        end
      end

      context 'when receiving SIGINT' do
        context 'with an interactor' do
          let(:interactor) do
            instance_double(
              Guard::Interactor,
              thread: instance_double(Thread))
          end
          before { allow(Guard).to receive(:interactor) { interactor } }

          it 'delegates to the Pry thread' do
            expect(Guard.interactor).to receive(:handle_interrupt)
            Process.kill :INT, Process.pid
            sleep 1
          end
        end
      end
    end
  end

  describe '._setup_notifier' do
    context 'with the notify option enabled' do
      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV['GUARD_NOTIFY'] = nil }

        it 'turns on the notifier on' do
          expect(::Guard::Notifier).to receive(:turn_on)

          allow(Listen).to receive(:to).with(Dir.pwd, {})
          ::Guard.setup(notify: true)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV['GUARD_NOTIFY'] = 'true' }

        it 'turns on the notifier on' do
          expect(::Guard::Notifier).to receive(:turn_on)

          allow(Listen).to receive(:to).with(Dir.pwd, {})
          ::Guard.setup(notify: true)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV['GUARD_NOTIFY'] = 'false' }

        it 'turns on the notifier off' do
          expect(::Guard::Notifier).to receive(:turn_off)

          allow(Listen).to receive(:to).with(Dir.pwd, {})
          ::Guard.setup(notify: true)
        end
      end
    end

    context 'with the notify option disable' do
      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV['GUARD_NOTIFY'] = nil }

        it 'turns on the notifier off' do
          expect(::Guard::Notifier).to receive(:turn_off)

          allow(Listen).to receive(:to).with(Dir.pwd, {})
          ::Guard.setup(notify: false)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV['GUARD_NOTIFY'] = 'true' }

        it 'turns on the notifier on' do
          expect(::Guard::Notifier).to receive(:turn_off)

          allow(Listen).to receive(:to).with(Dir.pwd, {})
          ::Guard.setup(notify: false)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV['GUARD_NOTIFY'] = 'false' }

        it 'turns on the notifier off' do
          expect(::Guard::Notifier).to receive(:turn_off)

          allow(Listen).to receive(:to).with(Dir.pwd, {})
          ::Guard.setup(notify: false)
        end
      end
    end
  end

  describe '._setup_notifier' do
    context 'with the notify option enabled' do
      let(:options) { Guard::Options.new(notify: true) }
      before { allow(::Guard).to receive(:options) { options } }

      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV['GUARD_NOTIFY'] = nil }

        it_should_behave_like 'notifier enabled'
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV['GUARD_NOTIFY'] = 'true' }

        it_should_behave_like 'notifier enabled'
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV['GUARD_NOTIFY'] = 'false' }

        it_should_behave_like 'notifier disabled'
      end
    end

    context 'with the notify option disabled' do
      let(:options) { Guard::Options.new(notify: false) }
      before { allow(::Guard).to receive(:options) { options } }

      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV['GUARD_NOTIFY'] = nil }

        it_should_behave_like 'notifier disabled'
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV['GUARD_NOTIFY'] = 'true' }

        it_should_behave_like 'notifier disabled'
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV['GUARD_NOTIFY'] = 'false' }

        it_should_behave_like 'notifier disabled'
      end
    end
  end

  describe '.interactor' do
    context 'with CLI options' do
      before do
        @interactor_enabled       = Guard::Interactor.enabled?
        Guard::Interactor.enabled = true
      end
      after { Guard::Interactor.enabled = @interactor_enabled }

      context 'with interactions enabled' do
        before do
          allow(Guard::Notifier).to receive(:turn_on)
          allow(Listen).to receive(:to).with(Dir.pwd, {})
          Guard.setup(no_interactions: false)
        end

        it_should_behave_like 'interactor enabled'
      end

      context 'with interactions disabled' do
        before do
          allow(Guard::Notifier).to receive(:turn_on)
          allow(Listen).to receive(:to).with(Dir.pwd, {})
          Guard.setup(no_interactions: true)
        end

        it_should_behave_like 'interactor disabled'
      end
    end

    context 'with DSL options' do
      before { @interactor_enabled = Guard::Interactor.enabled? }
      after { Guard::Interactor.enabled = @interactor_enabled }

      context 'with interactions enabled' do
        before do
          Guard::Interactor.enabled = true
          allow(Guard::Notifier).to receive(:turn_on)
          allow(Listen).to receive(:to).with(Dir.pwd, {})
          Guard.setup
        end

        it_should_behave_like 'interactor enabled'
      end

      context 'with interactions disabled' do
        before do
          Guard::Interactor.enabled = false
          allow(Guard::Notifier).to receive(:turn_on)
          allow(Listen).to receive(:to).with(Dir.pwd, {})
          Guard.setup
        end

        it_should_behave_like 'interactor disabled'
      end
    end
  end

  describe '._debug_command_execution' do
    subject { Guard.setup }

    before do
      allow(Listen).to receive(:to).with(Dir.pwd, {})
      allow(Guard::Notifier).to receive(:turn_on)

      # Unstub global stub
      allow(Guard).to receive(:_debug_command_execution).and_call_original

      @original_system  = Kernel.method(:system)
      @original_command = Kernel.method(:`)
      Kernel.send(:define_method, :original_system, proc { |*_args| })
      Kernel.send(:define_method, :original_backtick, proc { |*_args| })
    end

    after do
      Kernel.send(:remove_method, :system)
      Kernel.send(:remove_method, :`)
      Kernel.send(:remove_method, :original_system)
      Kernel.send(:remove_method, :original_backtick)

      Kernel.send(:define_method, :system, @original_system.to_proc)
      Kernel.send(:define_method, :`, @original_command.to_proc)
    end

    it 'outputs Kernel.#system method parameters' do
      expect(::Guard::UI).to receive(:debug).
        with('Command execution: echo test')

      expect(Kernel).to receive(:original_system).
        with('echo', 'test') { true }

      subject.send :_debug_command_execution

      expect(system('echo', 'test')).to be_truthy
    end

    it 'outputs Kernel.#` method parameters' do
      expect(::Guard::UI).to receive(:debug).
        with('Command execution: echo test')

      expect(Kernel).to receive(:original_backtick).
        with('echo test') { "test\n" }

      subject.send :_debug_command_execution
      expect(`echo test`).to eq "test\n"
    end
  end
end
