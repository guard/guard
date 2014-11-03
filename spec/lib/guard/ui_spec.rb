RSpec.describe Guard::UI do
  let(:interactor) { instance_double(Guard::Interactor) }
  let(:evaluator) { instance_double(Guard::Guardfile::Evaluator) }
  let(:options) { instance_double(Guard::Options) }
  let(:scope) { double("scope") }
  let(:logger) { instance_double(Lumberjack::Logger) }

  before do
    allow(Guard::Interactor).to receive(:new).and_return(interactor)
    allow(Guard).to receive(:options).and_return(options)
    allow(Guard).to receive(:scope).and_return(scope)

    allow(Notifier).to receive(:turn_on) {}

    allow(Lumberjack::Logger).to receive(:new).and_return(logger)

    # The spec helper stubs all UI classes, so other specs doesn't have
    # to explicit take care of it. We unstub and move the stubs one layer
    # down just for this spec.
    allow(UI).to receive(:info).and_call_original
    allow(UI).to receive(:warning).and_call_original
    allow(UI).to receive(:error).and_call_original
    allow(UI).to receive(:deprecation).and_call_original
    allow(UI).to receive(:debug).and_call_original

    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
    allow(logger).to receive(:error)
    allow(logger).to receive(:debug)

    allow($stderr).to receive(:print)

    allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
    allow(evaluator).to receive(:evaluate_guardfile)
  end

  after do
    # TODO: a session object would be better
    UI.reset_logger

    UI.options = {
      level: :info,
      device: $stderr,
      template: ":time - :severity - :message",
      time_format: "%H:%M:%S"
    }
  end

  describe ".logger" do
    it "returns the logger instance" do
      expect(UI.logger).to be(logger)
    end

    it "sets the logger device" do
      expect(Lumberjack::Logger).to receive(:new).with($stderr, UI.options)
      UI.logger
    end
  end

  describe ".options=" do
    it "sets the logger options" do
      UI.options = { hi: :ho }
      expect(UI.options[:hi]).to eq :ho
    end
  end

  describe ".info" do
    it "resets the line with the :reset option" do
      expect(UI).to receive :reset_line
      UI.info("Info message",  reset: true)
    end

    it "logs the message to with the info severity" do
      expect(UI.logger).to receive(:info).with("Info message", "Guard::Ui")
      UI.info "Info message"
    end

    context "with the :only option" do
      before { UI.options[:only] = /A/ }

      it "shows only the matching messages" do
        expect(UI.logger).to receive(:info).with("Info message", "A")
        expect(UI.logger).to_not receive(:info).with("Info message", "B")
        expect(UI.logger).to_not receive(:info).with("Info message", "C")

        UI.info "Info message", plugin: "A"
        UI.info "Info message", plugin: "B"
        UI.info "Info message", plugin: "C"
      end
    end

    context "with the :except option" do
      before { UI.options[:except] = /A/ }

      it "shows only the matching messages" do
        expect(UI.logger).to_not receive(:info).with("Info message", "A")
        expect(UI.logger).to receive(:info).with("Info message", "B")
        expect(UI.logger).to receive(:info).with("Info message", "C")

        UI.info "Info message", plugin: "A"
        UI.info "Info message", plugin: "B"
        UI.info "Info message", plugin: "C"
      end
    end
  end

  describe ".warning" do
    it "resets the line with the :reset option" do
      expect(UI).to receive :reset_line
      UI.warning("Warn message",  reset: true)
    end

    it "logs the message to with the warn severity" do
      expect(UI.logger).to receive(:warn).
        with("\e[0;33mWarn message\e[0m", "Guard::Ui")

      UI.warning "Warn message"
    end

    context "with the :only option" do
      before { UI.options[:only] = /A/ }

      it "shows only the matching messages" do
        expect(UI.logger).to receive(:warn).
          with("\e[0;33mWarn message\e[0m", "A")

        expect(UI.logger).to_not receive(:warn).
          with("\e[0;33mWarn message\e[0m", "B")

        expect(UI.logger).to_not receive(:warn).
          with("\e[0;33mWarn message\e[0m", "C")

        UI.warning "Warn message", plugin: "A"
        UI.warning "Warn message", plugin: "B"
        UI.warning "Warn message", plugin: "C"
      end
    end

    context "with the :except option" do
      before { UI.options[:except] = /A/ }

      it "shows only the matching messages" do
        expect(UI.logger).to_not receive(:warn).
          with("\e[0;33mWarn message\e[0m", "A")

        expect(UI.logger).to receive(:warn).
          with("\e[0;33mWarn message\e[0m", "B")

        expect(UI.logger).to receive(:warn).
          with("\e[0;33mWarn message\e[0m", "C")

        UI.warning "Warn message", plugin: "A"
        UI.warning "Warn message", plugin: "B"
        UI.warning "Warn message", plugin: "C"
      end
    end
  end

  describe ".error" do
    it "resets the line with the :reset option" do
      expect(UI).to receive :reset_line
      UI.error("Error message",  reset: true)
    end

    it "logs the message to with the error severity" do
      expect(UI.logger).to receive(:error).
        with("\e[0;31mError message\e[0m", "Guard::Ui")

      UI.error "Error message"
    end

    context "with the :only option" do
      before { UI.options[:only] = /A/ }

      it "shows only the matching messages" do
        expect(UI.logger).to receive(:error).
          with("\e[0;31mError message\e[0m", "A")

        expect(UI.logger).to_not receive(:error).
          with("\e[0;31mError message\e[0m", "B")

        expect(UI.logger).to_not receive(:error).
          with("\e[0;31mError message\e[0m", "C")

        UI.error "Error message", plugin: "A"
        UI.error "Error message", plugin: "B"
        UI.error "Error message", plugin: "C"
      end
    end

    context "with the :except option" do
      before { UI.options[:except] = /A/ }

      it "shows only the matching messages" do
        expect(UI.logger).to_not receive(:error).
          with("\e[0;31mError message\e[0m", "A")

        expect(UI.logger).to receive(:error).
          with("\e[0;31mError message\e[0m", "B")

        expect(UI.logger).to receive(:error).
          with("\e[0;31mError message\e[0m", "C")

        UI.error "Error message", plugin: "A"
        UI.error "Error message", plugin: "B"
        UI.error "Error message", plugin: "C"
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
        expect(UI.logger).to_not receive(:warn)
        UI.deprecation "Deprecator message"
      end
    end

    context "with GUARD_GEM_SILENCE_DEPRECATIONS unset" do
      let(:value) { nil }

      it "resets the line with the :reset option" do
        expect(UI).to receive :reset_line
        UI.deprecation("Deprecator message",  reset: true)
      end

      it "logs the message to with the warn severity" do
        expect(UI.logger).to receive(:warn).
          with("\e[0;33mDeprecator message\e[0m", "Guard::Ui")

        UI.deprecation "Deprecator message"
      end

      context "with the :only option" do
        before { UI.options[:only] = /A/ }

        it "shows only the matching messages" do
          expect(UI.logger).to receive(:warn).
            with("\e[0;33mDeprecator message\e[0m", "A")

          expect(UI.logger).to_not receive(:warn).
            with("\e[0;33mDeprecator message\e[0m", "B")

          expect(UI.logger).to_not receive(:warn).
            with("\e[0;33mDeprecator message\e[0m", "C")

          UI.deprecation "Deprecator message", plugin: "A"
          UI.deprecation "Deprecator message", plugin: "B"
          UI.deprecation "Deprecator message", plugin: "C"
        end
      end

      context "with the :except option" do
        before { UI.options[:except] = /A/ }

        it "shows only the matching messages" do
          expect(UI.logger).to_not receive(:warn).
            with("\e[0;33mDeprecator message\e[0m", "A")

          expect(UI.logger).to receive(:warn).
            with("\e[0;33mDeprecator message\e[0m", "B")

          expect(UI.logger).to receive(:warn).
            with("\e[0;33mDeprecator message\e[0m", "C")

          UI.deprecation "Deprecator message", plugin: "A"
          UI.deprecation "Deprecator message", plugin: "B"
          UI.deprecation "Deprecator message", plugin: "C"
        end
      end
    end
  end

  describe ".debug" do
    it "resets the line with the :reset option" do
      expect(UI).to receive :reset_line
      UI.debug("Debug message",  reset: true)
    end

    it "logs the message to with the debug severity" do
      expect(UI.logger).to receive(:debug).
        with("\e[0;33mDebug message\e[0m", "Guard::Ui")

      UI.debug "Debug message"
    end

    context "with the :only option" do
      before { UI.options[:only] = /A/ }

      it "shows only the matching messages" do
        expect(UI.logger).to receive(:debug).
          with("\e[0;33mDebug message\e[0m", "A")

        expect(UI.logger).to_not receive(:debug).
          with("\e[0;33mDebug message\e[0m", "B")

        expect(UI.logger).to_not receive(:debug).
          with("\e[0;33mDebug message\e[0m", "C")

        UI.debug "Debug message", plugin: "A"
        UI.debug "Debug message", plugin: "B"
        UI.debug "Debug message", plugin: "C"
      end
    end

    context "with the :except option" do
      before { UI.options[:except] = /A/ }

      it "shows only the matching messages" do
        expect(UI.logger).to_not receive(:debug).
          with("\e[0;33mDebug message\e[0m", "A")

        expect(UI.logger).to receive(:debug).
          with("\e[0;33mDebug message\e[0m", "B")

        expect(UI.logger).to receive(:debug).
          with("\e[0;33mDebug message\e[0m", "C")

        UI.debug "Debug message", plugin: "A"
        UI.debug "Debug message", plugin: "B"
        UI.debug "Debug message", plugin: "C"
      end
    end
  end

  describe ".clear" do
    let(:terminal) { class_double(::Guard::Terminal) }

    before { stub_const("::Guard::Terminal", terminal) }

    context "with UI set up and ready" do
      before do
        # disable avoid calling clear during before()
        allow(options).to receive(:[]).with(:clear).and_return(false)

        # This shouldn't do anything except set instance var
        UI.setup(options)
      end

      context "when clear option is disabled" do
        it "does not clear the output" do
          expect(terminal).to_not receive(:clear)
          UI.clear
        end
      end

      context "when clear option is enabled" do
        before do
          allow(options).to receive(:[]).with(:clear).and_return(true)
        end

        context "when the screen is marked as needing clearing" do
          before { UI.clearable }

          it "clears the output" do
            expect(terminal).to receive(:clear)
            UI.clear
          end

          it "clears the output only once" do
            expect(terminal).to receive(:clear).once
            UI.clear
            UI.clear
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
              UI.clear
            end
          end
        end

        context "when the screen has just been cleared" do
          before { UI.clear }

          it "does not clear" do
            expect(terminal).to_not receive(:clear)
            UI.clear
          end

          context "when forced" do
            let(:opts) { { force: true } }

            it "clears the outputs if forced" do
              expect(terminal).to receive(:clear)
              UI.clear(opts)
            end
          end
        end
      end
    end
  end

  describe ".action_with_scopes" do
    let(:rspec) { double("Rspec", title: "Rspec") }
    let(:jasmine) { double("Jasmine", title: "Jasmine") }
    let(:group) { instance_double(Guard::Group, title: "Frontend") }

    context "with a plugins scope" do
      it "shows the plugin scoped action" do
        expect(UI).to receive(:info).with("Reload Rspec, Jasmine")
        UI.action_with_scopes("Reload",  plugins: [rspec, jasmine])
      end
    end

    context "with a groups scope" do
      it "shows the group scoped action" do
        allow(scope).to receive(:[]).with(:plugins).and_return([])
        expect(UI).to receive(:info).with("Reload Frontend")
        UI.action_with_scopes("Reload",  groups: [group])
      end
    end

    context "without a scope" do
      context "with a global plugin scope" do
        it "shows the global plugin scoped action" do
          plugins = [rspec, jasmine]
          allow(scope).to receive(:[]).with(:plugins).and_return(plugins)
          expect(UI).to receive(:info).with("Reload Rspec, Jasmine")
          UI.action_with_scopes("Reload", {})
        end
      end

      context "with a global group scope" do
        it "shows the global group scoped action" do
          allow(scope).to receive(:[]).with(:plugins).and_return([])
          allow(scope).to receive(:[]).with(:groups).and_return([group])
          expect(UI).to receive(:info).with("Reload Frontend")
          UI.action_with_scopes("Reload", {})
        end
      end
    end
  end
end
