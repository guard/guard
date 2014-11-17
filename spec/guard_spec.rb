require "guard"

RSpec.describe Guard do
  # Initialize before Guard::Interactor const is stubbed
  let!(:interactor) { instance_double(Guard::Interactor) }
  let!(:interactor_class) { class_double(Guard::Interactor) }

  let(:evaluator) { instance_double(Guard::Guardfile::Evaluator) }
  let(:guardfile) { File.expand_path("Guardfile") }
  let(:traps) { Guard::Internals::Traps }

  before do
    stub_const("Guard::Interactor", interactor_class)
    allow(interactor_class).to receive(:new).and_return(interactor)
    allow(Dir).to receive(:chdir)
    allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
    allow(evaluator).to receive(:evaluate_guardfile)

    stub_notifier
  end

  describe ".plugins" do
    before do
      Guard.reset_plugins

      stub_const "Guard::FooBar", Class.new(Guard::Plugin)
      stub_const "Guard::FooBaz", Class.new(Guard::Plugin)

      @guard_foo_bar_backend = described_class.add_plugin(
        "foo_bar",
        group: "backend")

      @guard_foo_baz_backend = described_class.add_plugin(
        "foo_baz",
        group: "backend")

      @guard_foo_bar_frontend = described_class.add_plugin(
        "foo_bar",
        group: "frontend")

      @guard_foo_baz_frontend = described_class.add_plugin(
        "foo_baz",
        group: "frontend")

    end

    it "return @plugins without any argument" do
      expect(described_class.plugins).
        to eq subject.instance_variable_get("@plugins")
    end

    context "find a plugin by as string" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins("foo-bar")).
          to eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end
    end

    context "find a plugin by as symbol" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(:'foo-bar')).
          to eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "returns an empty array when no plugin is found" do
        expect(described_class.plugins("foo-foo")).to be_empty
      end
    end

    context "find plugins matching a regexp" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(/^foobar/)).
          to eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "returns an empty array when no plugin is found" do
        expect(described_class.plugins(/foo$/)).to be_empty
      end
    end

    context "find plugins by their group as a string" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(group: "backend")).
          to eq [@guard_foo_bar_backend, @guard_foo_baz_backend]
      end
    end

    context "find plugins by their group as a symbol" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(group: :frontend)).
          to eq [@guard_foo_bar_frontend, @guard_foo_baz_frontend]
      end

      it "returns an empty array when no plugin is found" do
        expect(described_class.plugins(group: :unknown)).to be_empty
      end
    end

    context "find plugins by their group & name" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(group: "backend", name: "foo-bar")).
          to eq [@guard_foo_bar_backend]
      end

      it "returns an empty array when no plugin is found" do
        expect(described_class.plugins(group: :unknown, name: :'foo-baz')).
          to be_empty
      end
    end
  end

  describe ".plugin" do
    before do
      Guard.reset_plugins

      stub_const "Guard::FooBar", Class.new(Guard::Plugin)
      stub_const "Guard::FooBaz", Class.new(Guard::Plugin)
      @guard_foo_bar_backend = described_class.add_plugin(
        "foo_bar",
        group: "backend")

      @guard_foo_baz_backend = described_class.add_plugin(
        "foo_baz",
        group: "backend")

      @guard_foo_bar_frontend = described_class.add_plugin(
        "foo_bar",
        group: "frontend")

      @guard_foo_baz_frontend = described_class.add_plugin(
        "foo_baz",
        group: "frontend")
    end

    context "find a plugin by a string" do
      it "returns the first plugin found" do
        expect(described_class.plugin("foo-bar")).to eq @guard_foo_bar_backend
      end
    end

    context "find a plugin by a symbol" do
      it "returns the first plugin found" do
        expect(described_class.plugin(:'foo-bar')).to eq @guard_foo_bar_backend
      end

      it "returns nil when no plugin is found" do
        expect(described_class.plugin("foo-foo")).to be_nil
      end
    end

    context "find plugins matching a regexp" do
      it "returns the first plugin found" do
        expect(described_class.plugin(/^foobar/)).to eq @guard_foo_bar_backend
      end

      it "returns nil when no plugin is found" do
        expect(described_class.plugin(/foo$/)).to be_nil
      end
    end

    context "find a plugin by its group as a string" do
      it "returns the first plugin found" do
        expect(described_class.plugin(group: "backend")).
          to eq @guard_foo_bar_backend
      end
    end

    context "find plugins by their group as a symbol" do
      it "returns the first plugin found" do
        expect(described_class.plugin(group: :frontend)).
          to eq @guard_foo_bar_frontend
      end

      it "returns nil when no plugin is found" do
        expect(described_class.plugin(group: :unknown)).to be_nil
      end
    end

    context "find plugins by their group & name" do
      it "returns the first plugin found" do
        expect(described_class.plugin(group: "backend", name: "foo-bar")).
          to eq @guard_foo_bar_backend
      end

      it "returns nil when no plugin is found" do
        expect(described_class.plugin(group: :unknown, name: :'foo-baz')).
          to be_nil
      end
    end
  end

  describe ".groups" do
    subject do
      allow(Listen).to receive(:to).with(Dir.pwd, {})
      guard           = ::Guard.setup
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    context "without no argument" do
      it "returns all groups" do
        expect(subject.groups).to eq subject.instance_variable_get("@groups")
      end
    end

    context "with a string argument" do
      it "returns an array of groups if plugins are found" do
        expect(subject.groups("backend")).to eq [@group_backend]
      end
    end

    context "with a symbol argument matching a group" do
      it "returns an array of groups if plugins are found" do
        expect(subject.groups(:backend)).to eq [@group_backend]
      end
    end

    context "with a symbol argument not matching a group" do
      it "returns an empty array when no group is found" do
        expect(subject.groups(:foo)).to be_empty
      end
    end

    context "with a regexp argument matching a group" do
      it "returns an array of groups" do
        expect(subject.groups(/^back/)).to eq [@group_backend, @group_backflip]
      end
    end

    context "with a regexp argument not matching a group" do
      it "returns an empty array when no group is found" do
        expect(subject.groups(/back$/)).to be_empty
      end
    end
  end

  describe ".group" do

    subject do
      allow(Listen).to receive(:to).with(Dir.pwd, {})

      guard           = ::Guard.setup

      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    context "with a string argument" do
      it "returns the first group found" do
        expect(subject.group("backend")).to eq @group_backend
      end
    end

    context "with a symbol argument" do
      it "returns the first group found" do
        expect(subject.group(:backend)).to eq @group_backend
      end
    end

    context "with a symbol argument not matching a group" do
      it "returns nil when no group is found" do
        expect(subject.group(:foo)).to be_nil
      end
    end

    context "with a regexp argument matching a group" do
      it "returns the first group found" do
        expect(subject.group(/^back/)).to eq @group_backend
      end
    end

    context "with a regexp argument not matching a group" do
      it "returns nil when no group is found" do
        expect(subject.group(/back$/)).to be_nil
      end
    end
  end

  describe ".add_plugin" do
    let(:plugin_util) { instance_double(Guard::PluginUtil) }
    let(:guard_rspec) { double("some_plugin_instance") }

    before do
      expect(::Guard::PluginUtil).to receive(:new).with("rspec") { plugin_util }
      allow(plugin_util).to receive(:initialize_plugin) { guard_rspec }

      ::Guard.reset_plugins
    end

    it "delegates the plugin instantiation to Guard::PluginUtil" do
      expect(plugin_util).to receive(:initialize_plugin).
        with(watchers: ["watcher"], group: "foo")

      ::Guard.add_plugin("rspec", watchers: ["watcher"], group: "foo")
    end

    it "adds guard to the @plugins array" do
      ::Guard.add_plugin("rspec")

      expect(::Guard.plugins).to eq [guard_rspec]
    end
  end

  describe ".remove_plugin" do
    before do
      # TODO: these are pretty useless to be justified as methods
      ::Guard.reset_groups
      ::Guard.reset_plugins

      stub_const "Guard::Foo", Class.new(Guard::Plugin)
      stub_const "Guard::Bar", Class.new(Guard::Plugin)
      stub_const "Guard::Baz", Class.new(Guard::Plugin)

      @foo = ::Guard.add_plugin("foo", group: "frontend")
      @bar = ::Guard.add_plugin("bar", group: "backend")
      @baz = ::Guard.add_plugin("baz", group: "backend")
    end

    context "with 3 existing plugins" do
      it "removes given group" do
        ::Guard.remove_plugin(@bar)
        expect(::Guard.plugins).to eq [@foo, @baz]
      end
    end

  end

  describe ".add_group" do
    before { ::Guard.reset_groups }

    it "accepts group name as string" do
      ::Guard.add_group("backend")

      expect(::Guard.groups.map(&:name)).to eq [:common, :default, :backend]
    end

    it "accepts group name as symbol" do
      ::Guard.add_group(:backend)

      expect(::Guard.groups.map(&:name)).to eq [:common, :default, :backend]
    end

    it "accepts options" do
      ::Guard.add_group(:backend,  halt_on_fail: true)

      expect(::Guard.groups[0].options).to eq({})
      expect(::Guard.groups[1].options).to eq({})
      expect(::Guard.groups[2].options).to eq(halt_on_fail: true)
    end
  end

  # TODO: setup has too many responsibilities
  describe ".setup" do

    subject { Guard.setup(options) }

    let(:options) { { my_opts: true, guardfile: guardfile } }

    let(:listener) { instance_double(Listen::Listener) }

    before do
      allow(Listen).to receive(:to).with(Dir.pwd, {}) { listener }

      allow(interactor_class).to receive(:new).and_return(interactor)

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    it "returns itself for chaining" do
      expect(subject).to be Guard
    end

    it "initializes the plugins" do
      expect(subject.plugins.map(&:name)).to eq []
    end

    it "initializes the groups" do
      expect(subject.groups.map(&:name)).to eq [:common, :default]
      expect(subject.groups.map(&:options)).to eq [{}, {}]
    end

    it "lazily initializes the options" do
      expect(subject.options[:my_opts]).to be_truthy
    end

    it "initializes the listener" do
      expect(subject.listener).to be(listener)
    end

    it "initializes the interactor" do
      expect(interactor_class).to receive(:new).with(false)
      subject
    end

    it "respect the watchdir option" do
      if Gem.win_platform?
        expect(Listen).to receive(:to).
          with("C:/usr", {}) { listener }
      else
        expect(Listen).to receive(:to).
          with("/usr", {}) { listener }
      end

      Guard.setup(watchdir: "/usr")
    end

    it "respect the watchdir option with multiple directories" do
      if Gem.win_platform?
        expect(Listen).to receive(:to).
          with("C:/usr", "C:/bin", {}) { listener }
      else
        expect(Listen).to receive(:to).
          with("/usr", "/bin", {}) { listener }
      end

      ::Guard.setup(watchdir: ["/usr", "/bin"])
    end

    context "trapping signals" do
      before do
        allow(traps).to receive(:handle)
      end

      it "sets up USR1 trap for pausing" do
        expect(traps).to receive(:handle).with("USR1") { |_, &b| b.call }
        expect(Guard).to receive(:async_queue_add).
          with([:guard_pause, :paused])
        subject
      end

      it "sets up USR2 trap for unpausing" do
        expect(traps).to receive(:handle).with("USR2") { |_, &b| b.call }
        expect(Guard).to receive(:async_queue_add).
          with([:guard_pause, :unpaused])
        subject
      end

      it "sets up INT trap for cancelling or quitting interactor" do
        expect(traps).to receive(:handle).with("INT") { |_, &b| b.call }
        expect(interactor).to receive(:handle_interrupt)
        subject
      end
    end

    it "evaluates the Guardfile" do
      expect(Guard).to receive(:evaluate_guardfile)

      subject
    end

    it "displays an error message when no guard are defined in Guardfile" do
      expect(Guard::UI).to receive(:error).
        with("No plugins found in Guardfile, please add at least one.")

      subject
    end

    it "connects to the notifier" do
      expect(Guard::Notifier).to receive(:connect).with(notify: true)
      subject
    end

    context "without the group or plugin option" do
      it "initializes the empty scope" do
        expect(subject.scope).to eq(groups: [], plugins: [])
      end
    end

    context "with the group option" do
      let(:options) do
        {
          group:              %w(backend frontend),
          guardfile_contents: "group :backend do; end; "\
          "group :frontend do; end; group :excluded do; end"
        }
      end

      it "initializes the group scope" do
        expect(subject.scope[:plugins]).to be_empty
        expect(subject.scope[:groups].count).to be 2
        expect(subject.scope[:groups][0].name).to eq :backend
        expect(subject.scope[:groups][1].name).to eq :frontend
      end
    end

    context "with the plugin option" do
      let(:options) do
        {
          plugin:             %w(cucumber jasmine),
          guardfile_contents: "guard :jasmine do; end; "\
            "guard :cucumber do; end; guard :coffeescript do; end"
        }
      end

      before do
        stub_const "Guard::Jasmine", Class.new(Guard::Plugin)
        stub_const "Guard::Cucumber", Class.new(Guard::Plugin)
        stub_const "Guard::CoffeeScript", Class.new(Guard::Plugin)
      end

      it "initializes the plugin scope" do
        allow(Guard).to receive(:plugin).with("cucumber").
          and_return(Guard::Cucumber.new)

        allow(Guard).to receive(:plugin).with("jasmine").
          and_return(Guard::Jasmine.new)

        expect(subject.scope[:groups]).to be_empty
        expect(subject.scope[:plugins].count).to be 2
        expect(subject.scope[:plugins][0].class).to eq ::Guard::Cucumber
        expect(subject.scope[:plugins][1].class).to eq ::Guard::Jasmine
      end
    end

    context "when debug is set to true" do
      let(:options) { { debug: true } }
      it "does not set up debugging" do
        expect(Guard::Internals::Debugging).to receive(:start)
        subject
      end
    end

    context "when debug is set to false" do
      let(:options) { { debug: false } }
      it "sets up debugging" do
        expect(Guard::Internals::Debugging).to_not receive(:start)
        subject
      end
    end

    context "with latency option" do
      let(:options) { { latency: 1.5 } }

      it "passes option to listener" do
        expect(Listen).to receive(:to).
          with(anything,  latency: 1.5) { listener }
        subject
      end
    end

    context "with force_polling option" do
      let(:options) { { force_polling: true } }

      it "pass option to listener" do
        expect(Listen).to receive(:to).
          with(anything, force_polling: true) { listener }
        subject
      end
    end
  end

  describe ".reset_groups" do
    subject do
      allow(Listen).to receive(:to).with(Dir.pwd, {})

      stub_guardfile(" ")
      stub_user_guard_rb

      guard = Guard.setup(guardfile: guardfile)

      @group_backend = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    it "initializes default groups" do
      subject.reset_groups

      expect(subject.groups.map(&:name)).to eq [:common, :default]
      expect(subject.groups.map(&:options)).to eq [{}, {}]
    end
  end

  describe ".setup_scope" do
    subject { Guard.setup(options) }

    let(:guardfile) do
      %w(group guard).map do |scope|
        %w(foo bar baz).map do |name|
          "#{ scope } :#{ name } do; end;"
        end
      end.flatten.join
    end

    let(:listener) { instance_double(Listen::Listener) }

    before do
      stub_const "Guard::Foo", Class.new(Guard::Plugin)
      stub_const "Guard::Bar", Class.new(Guard::Plugin)
      stub_const "Guard::Baz", Class.new(Guard::Plugin)
      allow(Listen).to receive(:to).with(Dir.pwd, {}) { listener }
      stub_user_guard_rb
    end

    [:group, :plugin].each do |scope|
      context "with the global #{scope} option specified" do
        let(:options) do
          { :guardfile_contents => guardfile, scope => %w(foo bar) }
        end

        it "configures the scope according to the global option" do
          if scope == :group
            allow(Guard).to receive(:add_group).with("foo").
              and_return(Guard::Group.new("foo"))

            allow(Guard).to receive(:add_group).with("bar").
              and_return(Guard::Group.new("bar"))
          else
            allow(Guard).to receive(:plugin).with("foo").
              and_return(Guard::Foo.new)

            allow(Guard).to receive(:plugin).with("bar").
              and_return(Guard::Bar.new)
          end

          subject.setup_scope(scope => :baz)

          expect(subject.scope[:"#{scope}s"].map(&:name).map(&:to_s)).to \
            contain_exactly("foo", "bar")
        end
      end

      context "without the global #{scope} option specified" do
        let(:options) { { guardfile_contents: guardfile } }

        it "configures the scope according to the given option" do

          if scope == :group
            allow(Guard).to receive(:add_group).with(:baz).
              and_return(Guard::Group.new(:baz))
          else
            allow(Guard).to receive(:plugin).with(:baz).
              and_return(Guard::Baz.new)
          end

          subject.setup_scope(scope => :baz)

          result = subject.scope[:"#{scope}s"].map(&:name)
          expect(result.map(&:to_s)).to contain_exactly("baz")
        end
      end
    end
  end

  describe "._relative_pathname" do
    subject { Guard.send(:_relative_pathname, raw_path) }

    let(:pwd) { Pathname("/project") }

    before { allow(Pathname).to receive(:pwd).and_return(pwd) }

    context "with file in project directory" do
      let(:raw_path) { "/project/foo" }
      it { is_expected.to eq(Pathname("foo")) }
    end

    context "with file within project" do
      let(:raw_path) { "/project/spec/models/foo_spec.rb" }
      it { is_expected.to eq(Pathname("spec/models/foo_spec.rb")) }
    end

    context "with file in parent directory" do
      let(:raw_path) { "/foo" }
      it { is_expected.to eq(Pathname("../foo")) }
    end

    context "with file on another drive (e.g. Windows)" do
      let(:raw_path) { "d:/project/foo" }
      let(:pathname) { instance_double(Pathname) }

      before do
        allow_any_instance_of(Pathname).to receive(:relative_path_from).
          with(pwd).and_raise(ArgumentError)
      end

      it { is_expected.to eq(Pathname.new("d:/project/foo")) }
    end
  end

  # TODO: remove
  describe ".reset_plugins" do
    before do
      allow(Listen).to receive(:to).with(Dir.pwd, {})

      # TODO: clean this up (rework evaluator)
      stub_guardfile(" ")
      stub_user_guard_rb

      module Guard
        class FooBar < ::Guard::Plugin; end
      end
    end

    subject do
      ::Guard.setup(guardfile: guardfile).tap { |g| g.add_plugin(:foo_bar) }
    end

    after do
      ::Guard.instance_eval { remove_const(:FooBar) }
    end

    it "return clear the plugins array" do
      expect(subject.plugins.map(&:name)).to eq(%w(foobar))

      subject.reset_plugins

      expect(subject.plugins).to be_empty
    end
  end

  describe ".reset_options" do
    before do
      allow(Listen).to receive(:to).with(File.join(Dir.pwd, "abc"), {})
      allow(Listen).to receive(:to).with(Dir.pwd, {})

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    it "clears options to defaults" do
      Guard.setup(watchdir: "abc")
      Guard.reset_options({})
      expect(Guard.options).to include("watchdir" => nil)
    end

    it "merges defaults with provided options" do
      Guard.setup(group: "foo")
      Guard.reset_options(group: "bar")
      expect(Guard.options).to include("group" => "bar")
    end

    it "includes default options" do
      Guard.setup
      Guard.reset_options({})
      expect(Guard.options).to include("plugin" => [])
    end

    it "works without Guard.setup" do
      Guard.reset_options(group: "bar")
      expect(Guard.options).to include("group" => "bar")
      expect(Guard.options).to include("plugin" => [])
    end
  end

  describe ".evaluate_guardfile" do
    # Any plugin, so that we don't get error about no plugins
    # (other than built-in ones)
    let(:foo_plugin) { instance_double(Guard::Plugin, name: "Foo") }

    it "evaluates the Guardfile" do
      allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
      allow(Guard).to receive(:plugins).and_return([foo_plugin])
      expect(evaluator).to receive(:evaluate_guardfile)

      Guard.evaluate_guardfile
    end
  end

  # TODO: these should be interactor tests
  describe ".interactor" do
    subject { Guard::Interactor }

    before do
      allow(Listen).to receive(:to).with(Dir.pwd, {})
      allow(evaluator).to receive(:evaluate_guardfile)
      allow(interactor_class).to receive(:new).and_return(interactor)

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    context "with interactions enabled" do
      before { Guard.setup(no_interactions: false) }
      it { is_expected.to have_received(:new).with(false) }
    end

    context "with interactions disabled" do
      before { Guard.setup(no_interactions: true) }
      it { is_expected.to have_received(:new).with(true) }
    end
  end
end
