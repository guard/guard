require "spec_helper"

include Guard

describe UI do
  let(:interactor) { instance_double(Guard::Interactor) }
  let(:evaluator) { instance_double(Guard::Guardfile::Evaluator) }

  before do
    allow(Guard::Interactor).to receive(:new).and_return(interactor)

    allow(Notifier).to receive(:turn_on) {}

    # The spec helper stubs all UI classes, so other specs doesn't have
    # to explicit take care of it. We unstub and move the stubs one layer
    # down just for this spec.
    allow(UI).to receive(:info).and_call_original
    allow(UI).to receive(:warning).and_call_original
    allow(UI).to receive(:error).and_call_original
    allow(UI).to receive(:deprecation).and_call_original
    allow(UI).to receive(:debug).and_call_original

    allow(UI.logger).to receive(:info)
    allow(UI.logger).to receive(:warn)
    allow(UI.logger).to receive(:error)
    allow(UI.logger).to receive(:debug)

    allow($stderr).to receive(:print)

    allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
    allow(evaluator).to receive(:evaluate_guardfile)
  end

  after do
    UI.options = {
      level: :info,
      device: $stderr,
      template: ":time - :severity - :message",
      time_format: "%H:%M:%S"
    }

    allow(::UI).to receive(:info)
    allow(::UI).to receive(:warning)
    allow(::UI).to receive(:error)
    allow(::UI).to receive(:debug)
    allow(::UI).to receive(:deprecation)
  end

  describe ".logger" do
    it "returns the logger instance" do
      expect(UI.logger).to be_an_instance_of Lumberjack::Logger
    end

    it "sets the logger device" do
      expect(UI.logger.device.send(:stream)).to be $stderr
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
    context "with the :show_deprecation option set to false (default)" do
      before do
        allow(Listen).to receive(:to).with(Dir.pwd, {})
        Guard.setup(show_deprecations: false)
      end

      it "do not log" do
        expect(UI.logger).to_not receive(:warn)
        UI.deprecation "Deprecator message"
      end
    end

    context "with the :show_deprecation option set to true" do
      before do
        allow(Listen).to receive(:to).with(Dir.pwd, {})
        Guard.setup(show_deprecations: true)
      end

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
    context "when the Guard clear option is enabled" do
      before do
        allow(Sheller).to receive(:run).with("clear;")
        allow(Listen).to receive(:to).with(Dir.pwd, {})
        Guard.setup(clear: true)
      end

      it "clears the outputs if clearable" do
        UI.clearable
        expect(::Sheller).to receive(:run).with("clear;")
        UI.clear
      end

      it "does not clear the output if already cleared" do
        UI.clear
        expect(Sheller).to_not receive(:run)
        UI.clear
      end

      it "clears the outputs if forced" do
        UI.clear
        expect(Sheller).to receive(:run).with("clear;")
        UI.clear(force: true)
      end
    end

    context "when the Guard clear option is disabled" do
      before do
        allow(Listen).to receive(:to).with(Dir.pwd, {})
        Guard.setup(clear: false)
      end

      it "does not clear the output" do
        expect(::Guard::Sheller).to_not receive(:run)
        Guard::UI.clear
      end
    end
  end

  describe ".action_with_scopes" do
    before do
      allow(Listen).to receive(:to).with(Dir.pwd, {})
      Guard.setup
    end

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
        expect(UI).to receive(:info).with("Reload Frontend")
        UI.action_with_scopes("Reload",  groups: [group])
      end
    end

    context "without a scope" do
      context "with a global plugin scope" do
        it "shows the global plugin scoped action" do
          Guard.scope = { plugins: [rspec, jasmine] }
          expect(UI).to receive(:info).with("Reload Rspec, Jasmine")
          UI.action_with_scopes("Reload", {})
        end
      end

      context "with a global group scope" do
        it "shows the global group scoped action" do
          Guard.scope = { groups: [group] }
          expect(UI).to receive(:info).with("Reload Frontend")
          UI.action_with_scopes("Reload", {})
        end
      end
    end
  end
end
