require "guard/config"

unless Guard::Config.new.strict?

  # require guard, to avoid circular require
  require "guard"
  # require "guard/deprecated/guard"

  require "guard/config"

  RSpec.describe Guard::Deprecated::Guard do
    let(:session) { instance_double("Guard::Internals::Session") }
    let(:state) { instance_double("Guard::Internals::State") }
    let(:plugins) { instance_double("Guard::Internals::Plugins") }
    let(:groups)  { instance_double("Guard::Internals::Groups") }
    let(:scope)  { instance_double("Guard::Internals::Scope") }

    subject do
      module TestModule
        def self.listener
        end

        def self._pluginless_guardfile?
          false
        end
      end
      TestModule.tap { |mod| described_class.add_deprecated(mod) }
    end

    before do
      allow(session).to receive(:evaluator_options).and_return({})
      allow(state).to receive(:scope).and_return(scope)
      allow(state).to receive(:session).and_return(session)
      allow(session).to receive(:plugins).and_return(plugins)
      allow(session).to receive(:groups).and_return(groups)
      allow(::Guard).to receive(:state).and_return(state)
      allow(Guard::UI).to receive(:deprecation)
      allow(plugins).to receive(:all)
      allow(groups).to receive(:all)
    end

    describe ".guards" do
      before do
      end

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::GUARDS)
        subject.guards
      end

      it "delegates to Plugins" do
        expect(plugins).to receive(:all).with(group: "backend")
        subject.guards(group: "backend")
      end
    end

    describe ".add_guard" do
      before { allow(plugins).to receive(:add).with("rspec", {}) }

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::ADD_GUARD)

        subject.add_guard("rspec")
      end

      it "delegates to Guard.plugins" do
        expect(subject).to receive(:add_plugin).with("rspec", group: "backend")

        subject.add_guard("rspec", group: "backend")
      end
    end

    describe ".get_guard_class" do
      let(:plugin_util) do
        instance_double("Guard::PluginUtil", plugin_class: true)
      end

      before do
        allow(Guard::PluginUtil).to receive(:new).with("rspec").
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
        expect(Guard::PluginUtil).to receive(:new).with("rspec") { plugin_util }
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
      before do
        allow(Guard::Guardfile::Evaluator).to receive(:new).
          and_return(double("evaluator"))
      end
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
      let(:options) { instance_double("Guard::Options") }

      before do
        allow(session).to receive(:options).and_return(options)
      end
      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::OPTIONS)
        subject.options
      end

      it "provides an alternative implementation" do
        expect(session).to receive(:options).and_return(options)
        expect(subject.options).to be(options)
      end
    end

    describe ".add_group" do
      before do
        allow(groups).to receive(:add)
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::ADD_GROUP)
        subject.add_group(:foo)
      end

      it "adds a group" do
        group = instance_double("Guard::Group")
        expect(groups).to receive(:add).with(:foo, bar: 3).and_return(group)
        expect(subject.add_group(:foo, bar: 3)).to eq(group)
      end
    end

    describe ".add_plugin" do
      before do
        allow(plugins).to receive(:add)
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::ADD_PLUGIN)
        subject.add_plugin(:foo)
      end

      it "adds a plugin" do
        plugin = instance_double("Guard::Plugin")
        expect(plugins).to receive(:add).with(:foo, bar: 3).and_return(plugin)
        expect(subject.add_plugin(:foo, bar: 3)).to be(plugin)
      end
    end

    describe ".group" do
      let(:array) { instance_double(Array) }

      before do
        allow(groups).to receive(:all).with(:foo).and_return(array)
        allow(array).to receive(:first)
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::GROUP)
        subject.group(:foo)
      end

      it "provides a similar implementation" do
        group = instance_double("Guard::Group")
        expect(array).to receive(:first).and_return(group)
        expect(subject.group(:foo)).to be(group)
      end
    end

    describe ".plugin" do
      let(:array) { instance_double(Array) }
      let(:plugin) { instance_double("Guard::Plugin") }

      before do
        allow(plugins).to receive(:all).with(:foo).and_return(array)
        allow(array).to receive(:first).and_return(plugin)
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
        allow(groups).to receive(:all).with(:foo).and_return(array)
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
        allow(plugins).to receive(:all).with(:foo).and_return(array)
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
      let(:hash) { instance_double(Hash) }

      before do
        allow(scope).to receive(:to_hash).and_return(hash)
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::SCOPE)
        subject.scope
      end

      it "provides a similar implementation" do
        expect(subject.scope).to be(hash)
      end
    end

    describe ".scope=" do
      before do
        allow(scope).to receive(:from_interactor).with(foo: :bar)
      end

      it "show deprecation warning" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Guard::ClassMethods::SCOPE_ASSIGN)
        subject.scope = { foo: :bar }
      end

      it "provides a similar implementation" do
        expect(scope).to receive(:from_interactor).with(foo: :bar)
        subject.scope = { foo: :bar }
      end
    end
  end
end
