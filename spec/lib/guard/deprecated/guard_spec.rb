require "guard/config"

unless Guard::Config.new.strict?
  # require guard, to avoid circular require
  require "guard"

  require "guard/config"

  RSpec.describe Guard::Deprecated::Guard do
    subject do
      mod =
        Module.new do
          @engine = Guard::Engine.new(cmdline_opts: {})

          def self.engine
            @engine
          end

          def self.listener; end

          def self._pluginless_guardfile?
            false
          end

          extend self
        end
      mod.tap { |m| described_class.add_deprecated(m) }
    end

    describe ".guards" do
      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::GUARDS)

        subject.guards
      end

      it "delegates to Plugins" do
        expect(subject.engine.plugins).to receive(:all).with(group: "backend")

        subject.guards(group: "backend")
      end
    end

    describe ".add_guard" do
      before { allow(subject.engine.plugins).to receive(:add).with("rspec", {}) }

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::ADD_GUARD)

        subject.add_guard("rspec")
      end

      it "delegates to Guard.plugins" do
        expect(subject.engine.plugins).to receive(:add).with("rspec", group: "backend")

        subject.add_guard("rspec", group: "backend")
      end
    end

    describe ".get_guard_class" do
      let(:plugin_util) do
        instance_double("Guard::PluginUtil", plugin_class: true)
      end

      before do
        allow(Guard::PluginUtil).to receive(:new).with(engine: subject.engine, name: "rspec").
          and_return(plugin_util)
      end

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::GET_GUARD_CLASS)

        subject.get_guard_class("rspec")
      end

      it "delegates to Guard::PluginUtil" do
        expect(plugin_util).to receive(:plugin_class).
          with(fail_gracefully: false)

        subject.get_guard_class("rspec")
      end

      describe ":fail_gracefully" do
        it "pass it to get_guard_class" do
          expect(plugin_util).to receive(:plugin_class).
            with(fail_gracefully: true)

          subject.get_guard_class("rspec", true)
        end
      end
    end

    describe ".locate_guard" do
      let(:plugin_util) do
        instance_double("Guard::PluginUtil", plugin_location: true)
      end

      before do
        allow(Guard::PluginUtil).to receive(:new) { plugin_util }
      end

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::LOCATE_GUARD)

        subject.locate_guard("rspec")
      end

      it "delegates to Guard::PluginUtil" do
        expect(Guard::PluginUtil).to receive(:new).with(engine: subject.engine, name: "rspec") { plugin_util }
        expect(plugin_util).to receive(:plugin_location)

        subject.locate_guard("rspec")
      end
    end

    describe ".guard_gem_names" do
      before { allow(Guard::PluginUtil).to receive(:plugin_names) }

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::GUARD_GEM_NAMES)

        subject.guard_gem_names
      end

      it "delegates to Guard::PluginUtil" do
        expect(Guard::PluginUtil).to receive(:plugin_names)

        subject.guard_gem_names
      end
    end

    describe ".running" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::RUNNING)

        subject.running
      end
    end

    describe ".lock" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::LOCK)

        subject.lock
      end
    end

    describe ".listener=" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::LISTENER_ASSIGN)

        subject.listener = 123
      end

      it "provides and alternative implementation" do
        subject.listener = 123
      end
    end

    describe "reset_evaluator" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::RESET_EVALUATOR)

        subject.reset_evaluator({})
      end
    end

    describe "evaluator" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::EVALUATOR)

        subject.evaluator
      end
    end

    describe "evaluate_guardfile" do
      let(:evaluator) { instance_double("Guard::Guardfile::Evaluator") }

      before do
        allow(::Guard::Guardfile::Evaluator).to receive(:new).
          and_return(evaluator)
        allow(evaluator).to receive(:evaluate)
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::EVALUATOR)

        subject.evaluate_guardfile
      end

      it "evaluates the guardfile" do
        expect(evaluator).to receive(:evaluate)

        subject.evaluate_guardfile
      end
    end

    describe "options" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::OPTIONS)

        subject.options
      end

      describe ":clear" do
        before do
          allow(subject.engine.session).to receive(:clearing?).and_return(clearing)
        end

        context "when being set to true" do
          let(:clearing) { true }

          it "sets the clearing option accordingly" do
            expect(subject.engine.session).to receive(:clearing).with(true)

            subject.options[:clear] = true
          end
        end

        context "when being set to false" do
          let(:clearing) { false }

          it "sets the clearing option accordingly" do
            expect(subject.engine.session).to receive(:clearing).with(false)

            subject.options[:clear] = false
          end
        end

        context "when being read" do
          context "when not set" do
            let(:clearing) { false }

            it "provides an alternative implementation" do
              expect(subject.options).to include(clear: false)
            end
          end

          context "when set" do
            let(:clearing) { true }
            it "provides an alternative implementation" do
              expect(subject.options).to include(clear: true)
            end
          end
        end
      end
    end

    describe ".add_group" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::ADD_GROUP)

        subject.add_group(:foo)
      end

      it "adds a group" do
        expect(subject.add_group(:foo, bar: 3)).to eq(subject.engine.groups.find(:foo))
      end
    end

    describe ".add_plugin" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::ADD_PLUGIN)

        subject.add_plugin(:foo)
      end

      it "adds a plugin" do
        expect(subject.add_plugin(:foo, bar: 3)).to be(subject.engine.plugins.find(:foo))
      end
    end

    describe ".group" do
      let(:group) { instance_double("Guard::Group") }

      before do
        allow(subject.engine.groups).to receive(:all).with(:foo).and_return([group])
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::GROUP)
        subject.group(:foo)
      end

      it "provides a similar implementation" do
        expect(subject.group(:foo)).to be(group)
      end
    end

    describe ".plugin" do
      let(:plugin) { instance_double("Guard::Plugin") }

      before do
        allow(subject.engine.plugins).to receive(:all).with(:foo).and_return([plugin])
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::PLUGIN)

        subject.plugin(:foo)
      end

      it "provides a similar implementation" do
        expect(subject.plugin(:foo)).to be(plugin)
      end
    end

    describe ".groups" do
      let(:array) { instance_double(Array) }

      before do
        expect(subject.engine.groups).to receive(:all).with(:foo).and_return(array)
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::GROUPS)

        subject.groups(:foo)
      end

      it "provides a similar implementation" do
        expect(subject.groups(:foo)).to be(array)
      end
    end

    describe ".plugins" do
      let(:array) { instance_double(Array) }

      before do
        expect(subject.engine.plugins).to receive(:all).with(:foo).and_return(array)
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::PLUGINS)

        subject.plugins(:foo)
      end

      it "provides a similar implementation" do
        expect(subject.plugins(:foo)).to be(array)
      end
    end

    describe ".scope" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::SCOPE)

        subject.scope
      end

      it "provides a similar implementation" do
        expect(subject.scope).to eq(plugins: [], groups: [])
      end
    end

    describe ".scope=" do
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::SCOPE_ASSIGN)

        subject.scope = { foo: :bar }
      end

      it "provides a similar implementation" do
        expect(subject.engine.scope).to receive(:from_interactor).with(foo: :bar)

        subject.scope = { foo: :bar }
      end
    end
  end
end
