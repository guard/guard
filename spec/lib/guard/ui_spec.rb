# frozen_string_literal: true
require 'guard/notifier'

# NOTE: this is here so that no UI does not require anything,
# since it could be activated by guard plugins during development
# (it they are tested by other guard plugins)
#
# TODO: regardless, the dependency on Guard.state should be removed
#
require 'guard/ui'

require 'guard/internals/session'

RSpec.describe Guard::UI do
  let(:interactor) { instance_double('Guard::Interactor') }
  let(:logger) { instance_double('Lumberjack::Logger') }
  let(:config) { instance_double('Guard::UI::Config') }
  let(:logger_config) { instance_double('Guard::UI::Logger::Config') }

  let(:terminal) { class_double('Guard::Terminal') }

  let(:session) { instance_double('Guard::Internals::Session') }
  let(:state) { instance_double('Guard::Internals::State') }
  let(:scope) { instance_double('Guard::Internals::Scope') }

  before do
    allow(state).to receive(:scope).and_return(scope)
    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

    stub_const('Guard::Terminal', terminal)

    allow(Guard::Notifier).to receive(:turn_on) {}

    allow(Lumberjack::Logger).to receive(:new).and_return(logger)
    allow(Guard::UI::Config).to receive(:new).and_return(config)
    allow(Guard::UI::Logger::Config).to receive(:new).and_return(logger_config)

    # The spec helper stubs all UI classes, so other specs doesn't have
    # to explicit take care of it. We unstub and move the stubs one layer
    # down just for this spec.
    allow(Guard::UI).to receive(:info).and_call_original
    allow(Guard::UI).to receive(:warning).and_call_original
    allow(Guard::UI).to receive(:error).and_call_original
    allow(Guard::UI).to receive(:deprecation).and_call_original
    allow(Guard::UI).to receive(:debug).and_call_original

    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
    allow(logger).to receive(:error)
    allow(logger).to receive(:debug)

    allow(config).to receive(:device)
    allow(config).to receive(:only)
    allow(config).to receive(:except)

    allow(config).to receive(:logger_config).and_return(logger_config)

    allow($stderr).to receive(:print)
  end

  before do
    Guard::UI.options = nil
  end

  after do
    Guard::UI.reset_logger
    Guard::UI.options = nil
  end

  describe '.logger' do
    before do
      allow(config).to receive(:device).and_return(device)
    end

    context 'with no logger set yet' do
      let(:device) { 'foo.log' }

      it 'returns the logger instance' do
        expect(Guard::UI.logger).to be(logger)
      end

      it 'sets the logger device' do
        expect(Lumberjack::Logger).to receive(:new)
          .with(device, logger_config)

        Guard::UI.logger
      end
    end
  end

  describe '.level=' do
    before do
      allow(logger).to receive(:level=)
      allow(logger_config).to receive(:level=)
    end

    context 'when logger is set up' do
      before { Guard::UI.logger }

      it "sets the logger's level" do
        level = Logger::WARN
        expect(logger).to receive(:level=).with(level)
        Guard::UI.level = level
      end

      it "sets the logger's config level" do
        level = Logger::WARN
        expect(logger_config).to receive(:level=).with(level)
        Guard::UI.level = level
      end
    end

    context 'when logger is not set up yet' do
      before { Guard::UI.reset_logger }

      it "sets the logger's config level" do
        level = Logger::WARN
        expect(logger_config).to receive(:level=).with(level)
        Guard::UI.level = level
      end

      it 'does not autocreate the logger' do
        level = Logger::WARN
        expect(logger).to_not receive(:level=).with(level)
        Guard::UI.level = level
      end
    end
  end

  describe '.options=' do
    let(:new_config) { instance_double('Guard::UI::Config') }

    before do
      allow(Guard::UI::Config).to receive(:new).with(hi: :ho)
        .and_return(new_config)

      allow(new_config).to receive(:[]).with(:hi).and_return(:ho)
    end

    it 'sets the logger options' do
      Guard::UI.options = { hi: :ho }
      expect(Guard::UI.options[:hi]).to eq :ho
    end
  end

  shared_examples_for 'a logger method' do
    it 'resets the line with the :reset option' do
      expect(Guard::UI).to receive :reset_line
      Guard::UI.send(ui_method, input, reset: true)
    end

    it 'logs the message with the given severity' do
      expect(logger).to receive(severity).with(output)
      Guard::UI.send(ui_method, input)
    end

    context 'with the :only option' do
      before { allow(config).to receive(:only).and_return(/A/) }

      it 'allows logging matching messages' do
        expect(logger).to receive(severity).with(output)
        Guard::UI.send(ui_method, input, plugin: 'A')
      end

      it 'prevents logging other messages' do
        expect(logger).to_not receive(severity)
        Guard::UI.send(ui_method, input, plugin: 'B')
      end
    end

    context 'with the :except option' do
      before { allow(config).to receive(:except).and_return(/A/) }

      it 'prevents logging matching messages' do
        expect(logger).to_not receive(severity)
        Guard::UI.send(ui_method, input, plugin: 'A')
      end

      it 'allows logging other messages' do
        expect(logger).to receive(severity).with(output)
        Guard::UI.send(ui_method, input, plugin: 'B')
      end
    end
  end

  describe '.info' do
    it_behaves_like 'a logger method' do
      let(:ui_method) { :info }
      let(:severity) { :info }
      let(:input) { 'Info' }
      let(:output) { 'Info' }
    end
  end

  describe '.warning' do
    it_behaves_like 'a logger method' do
      let(:ui_method) { :warning }
      let(:severity) { :warn }
      let(:input) { 'Warning' }
      let(:output) { "\e[0;33mWarning\e[0m" }
    end
  end

  describe '.error' do
    it_behaves_like 'a logger method' do
      let(:ui_method) { :error }
      let(:severity) { :error }
      let(:input) { 'Error' }
      let(:output) { "\e[0;31mError\e[0m" }
    end
  end

  describe '.deprecation' do
    before do
      allow(ENV).to receive(:[]).with('GUARD_GEM_SILENCE_DEPRECATIONS')
        .and_return(value)
    end

    context 'with GUARD_GEM_SILENCE_DEPRECATIONS set to 1' do
      let(:value) { '1' }

      it 'silences deprecations' do
        expect(Guard::UI.logger).to_not receive(:warn)
        Guard::UI.deprecation 'Deprecator message'
      end
    end

    context 'with GUARD_GEM_SILENCE_DEPRECATIONS unset' do
      let(:value) { nil }

      it_behaves_like 'a logger method' do
        let(:ui_method) { :deprecation }
        let(:severity) { :warn }
        let(:input) { 'Deprecated' }
        let(:output) do
          /^\e\[0;33mDeprecated\nDeprecation backtrace: .*\e\[0m$/m
        end
      end
    end
  end

  describe '.debug' do
    it_behaves_like 'a logger method' do
      let(:ui_method) { :debug }
      let(:severity) { :debug }
      let(:input) { 'Debug' }
      let(:output) { "\e[0;33mDebug\e[0m" }
    end
  end

  describe '.clear' do
    context 'with UI set up and ready' do
      before do
        allow(session).to receive(:clear?).and_return(false)
        Guard::UI.reset_and_clear
      end

      context 'when clear option is disabled' do
        it 'does not clear the output' do
          expect(terminal).to_not receive(:clear)
          Guard::UI.clear
        end
      end

      context 'when clear option is enabled' do
        before do
          allow(session).to receive(:clear?).and_return(true)
        end

        context 'when the screen is marked as needing clearing' do
          before { Guard::UI.clearable }

          it 'clears the output' do
            expect(terminal).to receive(:clear)
            Guard::UI.clear
          end

          it 'clears the output only once' do
            expect(terminal).to receive(:clear).once
            Guard::UI.clear
            Guard::UI.clear
          end

          context 'when the command fails' do
            before do
              allow(terminal).to receive(:clear)
                .and_raise(Errno::ENOENT, 'failed to run command')
            end

            it 'shows a warning' do
              expect(logger).to receive(:warn) do |arg|
                expect(arg).to match(/failed to run command/)
              end
              Guard::UI.clear
            end
          end
        end

        context 'when the screen has just been cleared' do
          before { Guard::UI.clear }

          it 'does not clear' do
            expect(terminal).to_not receive(:clear)
            Guard::UI.clear
          end

          context 'when forced' do
            let(:opts) { { force: true } }

            it 'clears the outputs if forced' do
              expect(terminal).to receive(:clear)
              Guard::UI.clear(opts)
            end
          end
        end
      end
    end
  end

  describe '.action_with_scopes' do
    let(:rspec) { double('Rspec', title: 'Rspec') }
    let(:jasmine) { double('Jasmine', title: 'Jasmine') }
    let(:group) { instance_double('Guard::Group', title: 'Frontend') }

    context 'with a plugins scope' do
      it 'shows the plugin scoped action' do
        allow(scope).to receive(:titles).with(plugins: [rspec, jasmine])
          .and_return(%w[Rspec Jasmine])

        expect(Guard::UI).to receive(:info).with('Reload Rspec, Jasmine')
        Guard::UI.action_with_scopes('Reload', plugins: [rspec, jasmine])
      end
    end

    context 'with a groups scope' do
      it 'shows the group scoped action' do
        allow(scope).to receive(:titles).with(groups: [group])
          .and_return(%w[Frontend])

        expect(Guard::UI).to receive(:info).with('Reload Frontend')
        Guard::UI.action_with_scopes('Reload', groups: [group])
      end
    end

    context 'without a scope' do
      context 'with a global plugin scope' do
        it 'shows the global plugin scoped action' do
          allow(scope).to receive(:titles).and_return(%w[Rspec Jasmine])
          expect(Guard::UI).to receive(:info).with('Reload Rspec, Jasmine')
          Guard::UI.action_with_scopes('Reload', {})
        end
      end

      context 'with a global group scope' do
        it 'shows the global group scoped action' do
          allow(scope).to receive(:titles).and_return(%w[Frontend])
          expect(Guard::UI).to receive(:info).with('Reload Frontend')
          Guard::UI.action_with_scopes('Reload', {})
        end
      end
    end
  end
end
