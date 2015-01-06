require "guard/notifier"

# NOTE: this is here so that no UI does not require anything,
# since it could be activated by guard plugins during development
# (it they are tested by other guard plugins)
#
# TODO: regardless, the dependency on Guard.state should be removed
#
require "guard/ui"

require "guard/internals/session"

RSpec.describe Guard::UI do
  let(:interactor) { instance_double("Guard::Interactor") }
  let(:logger) { instance_double("Lumberjack::Logger") }

  let(:terminal) { class_double("Guard::Terminal") }

  let(:session) { instance_double("Guard::Internals::Session") }
  let(:state) { instance_double("Guard::Internals::State") }
  let(:scope) { instance_double("Guard::Internals::Scope") }

  before do
    allow(state).to receive(:scope).and_return(scope)
    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

    stub_const("Guard::Terminal", terminal)

    allow(Guard::Notifier).to receive(:turn_on) {}

    allow(Lumberjack::Logger).to receive(:new).and_return(logger)

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

    allow($stderr).to receive(:print)
  end

  after do
    # TODO: a session object would be better
    Guard::UI.reset_logger

    Guard::UI.options = {
      level: :info,
      device: $stderr,
      template: ":time - :severity - :message",
      time_format: "%H:%M:%S"
    }
  end

  describe ".logger" do
    it "returns the logger instance" do
      expect(Guard::UI.logger).to be(logger)
    end

    it "sets the logger device" do
      expect(Lumberjack::Logger).to receive(:new).
        with($stderr, Guard::UI.options)

      Guard::UI.logger
    end
  end

  describe ".options=" do
    it "sets the logger options" do
      Guard::UI.options = { hi: :ho }
      expect(Guard::UI.options[:hi]).to eq :ho
    end
  end

  describe ".info" do
    it "resets the line with the :reset option" do
      expect(Guard::UI).to receive :reset_line
      Guard::UI.info("Info",  reset: true)
    end

    it "logs the message to with the info severity" do
      expect(Guard::UI.logger).to receive(:info).with("Info", "Guard::Ui")
      Guard::UI.info "Info"
    end

    context "with the :only option" do
      before { Guard::UI.options[:only] = /A/ }

      it "shows only the matching messages" do
        expect(Guard::UI.logger).to receive(:info).with("Info", "A")
        expect(Guard::UI.logger).to_not receive(:info).with("Info", "B")
        expect(Guard::UI.logger).to_not receive(:info).with("Info", "C")

        Guard::UI.info "Info", plugin: "A"
        Guard::UI.info "Info", plugin: "B"
        Guard::UI.info "Info", plugin: "C"
      end
    end

    context "with the :except option" do
      before { Guard::UI.options[:except] = /A/ }

      it "shows only the matching messages" do
        expect(Guard::UI.logger).to_not receive(:info).with("Info", "A")
        expect(Guard::UI.logger).to receive(:info).with("Info", "B")
        expect(Guard::UI.logger).to receive(:info).with("Info", "C")

        Guard::UI.info "Info", plugin: "A"
        Guard::UI.info "Info", plugin: "B"
        Guard::UI.info "Info", plugin: "C"
      end
    end
  end

  describe ".warning" do
    it "resets the line with the :reset option" do
      expect(Guard::UI).to receive :reset_line
      Guard::UI.warning("Warning",  reset: true)
    end

    it "logs the message to with the warn severity" do
      expect(Guard::UI.logger).to receive(:warn).
        with("\e[0;33mWarning\e[0m", "Guard::Ui")

      Guard::UI.warning "Warning"
    end

    context "with the :only option" do
      before { Guard::UI.options[:only] = /A/ }

      it "shows only the matching messages" do
        expect(Guard::UI.logger).to receive(:warn).
          with("\e[0;33mWarning\e[0m", "A")

        expect(Guard::UI.logger).to_not receive(:warn).
          with("\e[0;33mWarning\e[0m", "B")

        expect(Guard::UI.logger).to_not receive(:warn).
          with("\e[0;33mWarning\e[0m", "C")

        Guard::UI.warning "Warning", plugin: "A"
        Guard::UI.warning "Warning", plugin: "B"
        Guard::UI.warning "Warning", plugin: "C"
      end
    end

    context "with the :except option" do
      before { Guard::UI.options[:except] = /A/ }

      it "shows only the matching messages" do
        expect(Guard::UI.logger).to_not receive(:warn).
          with("\e[0;33mWarning\e[0m", "A")

        expect(Guard::UI.logger).to receive(:warn).
          with("\e[0;33mWarning\e[0m", "B")

        expect(Guard::UI.logger).to receive(:warn).
          with("\e[0;33mWarning\e[0m", "C")

        Guard::UI.warning "Warning", plugin: "A"
        Guard::UI.warning "Warning", plugin: "B"
        Guard::UI.warning "Warning", plugin: "C"
      end
    end
  end

  describe ".error" do
    it "resets the line with the :reset option" do
      expect(Guard::UI).to receive :reset_line
      Guard::UI.error("Error message",  reset: true)
    end

    it "logs the message to with the error severity" do
      expect(Guard::UI.logger).to receive(:error).
        with("\e[0;31mError message\e[0m", "Guard::Ui")

      Guard::UI.error "Error message"
    end

    context "with the :only option" do
      before { Guard::UI.options[:only] = /A/ }

      it "shows only the matching messages" do
        expect(Guard::UI.logger).to receive(:error).
          with("\e[0;31mError message\e[0m", "A")

        expect(Guard::UI.logger).to_not receive(:error).
          with("\e[0;31mError message\e[0m", "B")

        expect(Guard::UI.logger).to_not receive(:error).
          with("\e[0;31mError message\e[0m", "C")

        Guard::UI.error "Error message", plugin: "A"
        Guard::UI.error "Error message", plugin: "B"
        Guard::UI.error "Error message", plugin: "C"
      end
    end

    context "with the :except option" do
      before { Guard::UI.options[:except] = /A/ }

      it "shows only the matching messages" do
        expect(Guard::UI.logger).to_not receive(:error).
          with("\e[0;31mError message\e[0m", "A")

        expect(Guard::UI.logger).to receive(:error).
          with("\e[0;31mError message\e[0m", "B")

        expect(Guard::UI.logger).to receive(:error).
          with("\e[0;31mError message\e[0m", "C")

        Guard::UI.error "Error message", plugin: "A"
        Guard::UI.error "Error message", plugin: "B"
        Guard::UI.error "Error message", plugin: "C"
      end
    end
  end

  describe ".deprecation" do
    before do
      allow(ENV).to receive(:[]).with("GUARD_GEM_SILENCE_DEPRECATIONS").
        and_return(value)
    end

    context "with GUARD_GEM_SILENCE_DEPRECATIONS set to 1" do
      let(:value) { "1" }

      it "silences deprecations" do
        expect(Guard::UI.logger).to_not receive(:warn)
        Guard::UI.deprecation "Deprecator message"
      end
    end

    context "with GUARD_GEM_SILENCE_DEPRECATIONS unset" do
      let(:value) { nil }

      it "resets the line with the :reset option" do
        expect(Guard::UI).to receive :reset_line
        Guard::UI.deprecation("Deprecator message",  reset: true)
      end

      it "logs the message to with the warn severity" do
        expect(Guard::UI.logger).to receive(:warn).
          with(/Deprecator message/m, "Guard::Ui")

        Guard::UI.deprecation "Deprecator message"
      end

      context "with the :only option" do
        before { Guard::UI.options[:only] = /A/ }

        it "shows only the matching messages" do
          expect(Guard::UI.logger).to receive(:warn).
            with(/Deprecator message/, "A")

          expect(Guard::UI.logger).to_not receive(:warn).
            with(/Deprecator message/, "B")

          expect(Guard::UI.logger).to_not receive(:warn).
            with(/Deprecator message/, "C")

          Guard::UI.deprecation "Deprecator message", plugin: "A"
          Guard::UI.deprecation "Deprecator message", plugin: "B"
          Guard::UI.deprecation "Deprecator message", plugin: "C"
        end
      end

      context "with the :except option" do
        before { Guard::UI.options[:except] = /A/ }

        it "shows only the matching messages" do
          expect(Guard::UI.logger).to_not receive(:warn).
            with(/Deprecator message/, "A")

          expect(Guard::UI.logger).to receive(:warn).
            with(/Deprecator message/, "B")

          expect(Guard::UI.logger).to receive(:warn).
            with(/Deprecator message/, "C")

          Guard::UI.deprecation "Deprecator message", plugin: "A"
          Guard::UI.deprecation "Deprecator message", plugin: "B"
          Guard::UI.deprecation "Deprecator message", plugin: "C"
        end
      end
    end
  end

  describe ".debug" do
    it "resets the line with the :reset option" do
      expect(Guard::UI).to receive :reset_line
      Guard::UI.debug("Debug message",  reset: true)
    end

    it "logs the message to with the debug severity" do
      expect(Guard::UI.logger).to receive(:debug).
        with("\e[0;33mDebug message\e[0m", "Guard::Ui")

      Guard::UI.debug "Debug message"
    end

    context "with the :only option" do
      before { Guard::UI.options[:only] = /A/ }

      it "shows only the matching messages" do
        expect(Guard::UI.logger).to receive(:debug).
          with("\e[0;33mDebug message\e[0m", "A")

        expect(Guard::UI.logger).to_not receive(:debug).
          with("\e[0;33mDebug message\e[0m", "B")

        expect(Guard::UI.logger).to_not receive(:debug).
          with("\e[0;33mDebug message\e[0m", "C")

        Guard::UI.debug "Debug message", plugin: "A"
        Guard::UI.debug "Debug message", plugin: "B"
        Guard::UI.debug "Debug message", plugin: "C"
      end
    end

    context "with the :except option" do
      before { Guard::UI.options[:except] = /A/ }

      it "shows only the matching messages" do
        expect(Guard::UI.logger).to_not receive(:debug).
          with("\e[0;33mDebug message\e[0m", "A")

        expect(Guard::UI.logger).to receive(:debug).
          with("\e[0;33mDebug message\e[0m", "B")

        expect(Guard::UI.logger).to receive(:debug).
          with("\e[0;33mDebug message\e[0m", "C")

        Guard::UI.debug "Debug message", plugin: "A"
        Guard::UI.debug "Debug message", plugin: "B"
        Guard::UI.debug "Debug message", plugin: "C"
      end
    end
  end

  describe ".clear" do
    context "with UI set up and ready" do
      before do
        allow(session).to receive(:clear?).and_return(false)

        Guard::UI.reset_and_clear
      end

      context "when clear option is disabled" do
        it "does not clear the output" do
          expect(terminal).to_not receive(:clear)
          Guard::UI.clear
        end
      end

      context "when clear option is enabled" do
        before do
          allow(session).to receive(:clear?).and_return(true)
        end

        context "when the screen is marked as needing clearing" do
          before { Guard::UI.clearable }

          it "clears the output" do
            expect(terminal).to receive(:clear)
            Guard::UI.clear
          end

          it "clears the output only once" do
            expect(terminal).to receive(:clear).once
            Guard::UI.clear
            Guard::UI.clear
          end

          context "when the command fails" do
            before do
              allow(terminal).to receive(:clear).
                and_raise(Errno::ENOENT, "failed to run command")
            end

            it "shows a warning" do
              expect(logger).to receive(:warn) do |arg|
                expect(arg).to match(/failed to run command/)
              end
              Guard::UI.clear
            end
          end
        end

        context "when the screen has just been cleared" do
          before { Guard::UI.clear }

          it "does not clear" do
            expect(terminal).to_not receive(:clear)
            Guard::UI.clear
          end

          context "when forced" do
            let(:opts) { { force: true } }

            it "clears the outputs if forced" do
              expect(terminal).to receive(:clear)
              Guard::UI.clear(opts)
            end
          end
        end
      end
    end
  end

  describe ".action_with_scopes" do
    let(:rspec) { double("Rspec", title: "Rspec") }
    let(:jasmine) { double("Jasmine", title: "Jasmine") }
    let(:group) { instance_double("Guard::Group", title: "Frontend") }

    context "with a plugins scope" do
      it "shows the plugin scoped action" do
        allow(scope).to receive(:titles).with(plugins: [rspec, jasmine]).
          and_return(%w(Rspec Jasmine))

        expect(Guard::UI).to receive(:info).with("Reload Rspec, Jasmine")
        Guard::UI.action_with_scopes("Reload",  plugins: [rspec, jasmine])
      end
    end

    context "with a groups scope" do
      it "shows the group scoped action" do
        allow(scope).to receive(:titles).with(groups: [group]).
          and_return(%w(Frontend))

        expect(Guard::UI).to receive(:info).with("Reload Frontend")
        Guard::UI.action_with_scopes("Reload",  groups: [group])
      end
    end

    context "without a scope" do
      context "with a global plugin scope" do
        it "shows the global plugin scoped action" do
          allow(scope).to receive(:titles).and_return(%w(Rspec Jasmine))
          expect(Guard::UI).to receive(:info).with("Reload Rspec, Jasmine")
          Guard::UI.action_with_scopes("Reload", {})
        end
      end

      context "with a global group scope" do
        it "shows the global group scoped action" do
          allow(scope).to receive(:titles).and_return(%w(Frontend))
          expect(Guard::UI).to receive(:info).with("Reload Frontend")
          Guard::UI.action_with_scopes("Reload", {})
        end
      end
    end
  end
end
