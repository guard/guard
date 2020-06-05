# frozen_string_literal: true

require "guard/ui"

RSpec.describe Guard::UI do
  include_context "with engine"

  let(:logger) { instance_double("Lumberjack::Logger") }
  let(:terminal) { class_double("Guard::Terminal") }

  before do
    described_class.reset

    stub_const("Guard::Terminal", terminal)

    allow(Lumberjack::Logger).to receive(:new).and_return(logger)
    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
    allow(logger).to receive(:error)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:level=)
  end

  after { described_class.reset }

  describe ".logger" do
    before do
      allow(described_class.options).to receive(:device).and_return(device)
    end

    context "with no logger set yet" do
      let(:device) { "foo.log" }

      it "returns the logger instance" do
        expect(described_class.logger).to be(logger)
      end

      it "sets the logger device" do
        expect(Lumberjack::Logger).to receive(:new).with(device, described_class.logger_config)

        described_class.logger
      end
    end
  end

  describe ".level=" do
    let(:level) { Logger::WARN }

    context "when logger is set up" do
      before { described_class.logger }

      it "sets the logger's level" do
        expect(logger).to receive(:level=).with(level)

        described_class.level = level
      end

      it "sets the logger's config level" do
        expect(described_class.logger_config).to receive(:level=).with(level)

        described_class.level = level
      end
    end

    context "when logger is not set up yet" do
      before { described_class.reset }

      it "sets the logger's config level" do
        expect(described_class.logger_config).to receive(:level=).with(level)

        described_class.level = level
      end

      it "does not autocreate the logger" do
        expect(logger).to_not receive(:level=)

        described_class.level = level
      end
    end
  end

  describe ".options=" do
    it "sets the logger options" do
      described_class.options = { hi: :ho }

      expect(described_class.options[:hi]).to eq :ho
    end
  end

  shared_examples_for "a logger method" do
    it "resets the line with the :reset option" do
      expect(described_class).to receive :reset_line

      described_class.send(ui_method, input, reset: true)
    end

    it "logs the message with the given severity" do
      expect(logger).to receive(severity).with(output)

      described_class.send(ui_method, input)
    end

    context "with the :only option" do
      before { described_class.options = { only: /A/ } }

      it "allows logging matching messages" do
        expect(logger).to receive(severity).with(output)

        described_class.send(ui_method, input, plugin: "A")
      end

      it "prevents logging other messages" do
        expect(logger).to_not receive(severity)

        described_class.send(ui_method, input, plugin: "B")
      end
    end

    context "with the :except option" do
      before { described_class.options = { except: /A/ } }

      it "prevents logging matching messages" do
        expect(logger).to_not receive(severity)

        described_class.send(ui_method, input, plugin: "A")
      end

      it "allows logging other messages" do
        expect(logger).to receive(severity).with(output)

        described_class.send(ui_method, input, plugin: "B")
      end
    end
  end

  describe ".info" do
    it_behaves_like "a logger method" do
      let(:ui_method) { :info }
      let(:severity) { :info }
      let(:input) { "Info" }
      let(:output) { "Info" }
    end
  end

  describe ".warning" do
    it_behaves_like "a logger method" do
      let(:ui_method) { :warning }
      let(:severity) { :warn }
      let(:input) { "Warning" }
      let(:output) { "\e[0;33mWarning\e[0m" }
    end
  end

  describe ".error" do
    it_behaves_like "a logger method" do
      let(:ui_method) { :error }
      let(:severity) { :error }
      let(:input) { "Error" }
      let(:output) { "\e[0;31mError\e[0m" }
    end
  end

  describe ".deprecation" do
    before do
      allow(ENV).to receive(:[]).with("GUARD_GEM_SILENCE_DEPRECATIONS")
                                .and_return(value)
    end

    context "with GUARD_GEM_SILENCE_DEPRECATIONS set to 1" do
      let(:value) { "1" }

      it "silences deprecations" do
        expect(described_class.logger).to_not receive(:warn)

        described_class.deprecation "Deprecator message"
      end
    end

    context "with GUARD_GEM_SILENCE_DEPRECATIONS unset" do
      let(:value) { nil }

      it_behaves_like "a logger method" do
        let(:ui_method) { :deprecation }
        let(:severity) { :warn }
        let(:input) { "Deprecated" }
        let(:output) do
          /^\e\[0;33mDeprecated\nDeprecation backtrace: .*\e\[0m$/m
        end
      end
    end
  end

  describe ".debug" do
    it_behaves_like "a logger method" do
      let(:ui_method) { :debug }
      let(:severity) { :debug }
      let(:input) { "Debug" }
      let(:output) { "\e[0;33mDebug\e[0m" }
    end
  end

  describe ".clear" do
    context "with UI set up and ready" do
      before do
        allow(session).to receive(:clear?).and_return(false)
        described_class.reset_and_clear
      end

      context "when clear option is disabled" do
        it "does not clear the output" do
          expect(terminal).to_not receive(:clear)

          described_class.clear
        end
      end

      context "with no engine" do
        before do
          allow(described_class).to receive(:engine).and_return(nil)
        end

        context "when the screen is marked as needing clearing" do
          it "clears the output" do
            expect(terminal).to_not receive(:clear)

            described_class.clear
          end
        end
      end

      context "when clear option is enabled" do
        before do
          allow(session).to receive(:clear?).and_return(true)
          allow(described_class).to receive(:engine).and_return(engine)
        end

        context "when the screen is marked as needing clearing" do
          before { described_class.clearable! }

          it "clears the output" do
            expect(terminal).to receive(:clear)

            described_class.clear
          end

          it "clears the output only once" do
            expect(terminal).to receive(:clear).once

            described_class.clear
            described_class.clear
          end

          context "when the command fails" do
            before do
              allow(terminal).to receive(:clear)
                .and_raise(Errno::ENOENT, "failed to run command")
            end

            it "shows a warning" do
              expect(logger).to receive(:warn) do |arg|
                expect(arg).to match(/failed to run command/)
              end

              described_class.clear
            end
          end
        end

        context "when the screen has just been cleared" do
          before { described_class.clear }

          it "does not clear" do
            expect(terminal).to_not receive(:clear)

            described_class.clear
          end

          context "when forced" do
            let(:opts) { { force: true } }

            it "clears the outputs if forced" do
              expect(terminal).to receive(:clear)

              described_class.clear(opts)
            end
          end
        end
      end
    end
  end

  describe ".action_with_scopes" do
    context "with a plugins scope" do
      it "shows the plugin scoped action" do
        expect(described_class).to receive(:info).with("Reload Rspec, Jasmine")

        described_class.action_with_scopes("Reload", %w[Rspec Jasmine])
      end
    end

    context "with a groups scope" do
      it "shows the group scoped action" do
        expect(described_class).to receive(:info).with("Reload Frontend")

        described_class.action_with_scopes("Reload", ["Frontend"])
      end
    end

    context "without a scope" do
      context "with a global plugin scope" do
        it "shows the global plugin scoped action" do
          expect(described_class).to receive(:info).with("Reload Rspec, Jasmine")

          described_class.action_with_scopes("Reload", %w[Rspec Jasmine])
        end
      end
    end
  end
end
