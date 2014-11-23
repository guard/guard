require "guard/plugin"

require "guard/dsl"

RSpec.describe Guard::Dsl do

  let(:guardfile_evaluator) { instance_double(Guard::Guardfile::Evaluator) }
  let(:interactor) { instance_double(Guard::Interactor) }
  let(:listener) { instance_double("Listen::Listener") }

  let(:evaluator) do
    Proc.new do |contents|
      Guard::Dsl.new.evaluate(contents, "", 1)
    end
  end

  before do
    stub_user_guard_rb
    stub_const "Guard::Foo", instance_double(Guard::Plugin)
    stub_const "Guard::Bar", instance_double(Guard::Plugin)
    stub_const "Guard::Baz", instance_double(Guard::Plugin)
    allow(Guard::Notifier).to receive(:turn_on)
    allow(Listen).to receive(:to).with(Dir.pwd, {})
    allow(Guard::Interactor).to receive(:new).and_return(interactor)
    allow(::Guard).to receive(:listener) { listener }

    # For backtrace cleanup
    allow(ENV).to receive(:[]).with("GEM_HOME").and_call_original
    allow(ENV).to receive(:[]).with("GEM_PATH").and_call_original
  end

  describe "#ignore" do
    context "with ignore regexps" do
      let(:contents) { "ignore %r{^foo}, /bar/" }

      it "adds ignored regexps to the listener" do
        expect(listener).to receive(:ignore).
          with([/^foo/, /bar/]).and_return(listener)

        evaluator.call(contents)
      end
    end
  end

  describe "#ignore!" do
    context "when ignoring only foo* and *bar*" do
      let(:contents) { "ignore! %r{^foo}, /bar/" }

      it "replaces listener regexps" do
        expect(listener).to receive(:ignore!).
          with([[/^foo/, /bar/]]).and_return(listener)

        evaluator.call(contents)
      end
    end

    context "when filtering *.txt and *.zip and ignoring only foo*" do
      let(:contents) { "filter! %r{.txt$}, /.*\\.zip/\n ignore! %r{^foo}" }

      it "replaces listener ignores, but keeps filter! ignores" do
        allow(listener).to receive(:ignore!).
          with([[/.txt$/, /.*\.zip/]]).and_return(listener)

        expect(listener).to receive(:ignore!).
          with([[/.txt$/, /.*\.zip/], [/^foo/]]).and_return(listener)

        evaluator.call(contents)
      end
    end
  end

  describe "#filter" do
    context "with filter regexp" do
      let(:contents) { "filter %r{.txt$}, /.*.zip/" }

      it "adds ignored regexps to the listener" do
        expect(listener).to receive(:ignore).
          with([/.txt$/, /.*.zip/]).and_return(listener)

        evaluator.call(contents)
      end
    end
  end

  describe "#filter!" do
    context "when filter!" do
      let(:contents) {  "filter! %r{.txt$}, /.*.zip/" }

      it "replaces ignored regexps in the listener" do
        expect(listener).to receive(:ignore!).
          with([[/.txt$/, /.*.zip/]]).and_return(listener)

        evaluator.call(contents)
      end
    end

    context "with ignore! and filter!" do
      let(:contents) { "ignore! %r{^foo}\n filter! %r{.txt$}, /.*.zip/" }

      it "replaces listener ignores, but keeps guardfile ignore!" do
        expect(listener).to receive(:ignore!).
          with([[/^foo/]]).and_return(listener)

        expect(listener).to receive(:ignore!).
          with([[/^foo/], [/.txt$/, /.*.zip/]]).and_return(listener)

        evaluator.call(contents)
      end
    end
  end

  describe "#notification" do
    context "when notification" do
      let(:contents) { "notification :growl" }

      it "adds a notification to the notifier" do
        expect(::Guard::Notifier).to receive(:add).with(:growl,  silent: false)

        evaluator.call(contents)
      end
    end

    context "with multiple notifications" do
      let(:contents) do
        "notification :growl\nnotification :ruby_gntp, host: '192.168.1.5'"
      end

      it "adds multiple notifiers" do
        expect(::Guard::Notifier).to receive(:add).with(:growl,  silent: false)

        expect(::Guard::Notifier).to receive(:add).
          with(:ruby_gntp,  host: "192.168.1.5", silent: false)

        evaluator.call(contents)
      end
    end
  end

  describe "#interactor" do
    context "with interactor :off" do
      let(:contents) { "interactor :off" }
      it "disables the interactions with :off" do
        expect(Guard::Interactor).to receive(:enabled=).with(false)
        evaluator.call(contents)
      end
    end

    context "with interactor options" do
      let(:contents) { 'interactor option1: \'a\', option2: 123' }
      it "passes the options to the interactor" do
        expect(Guard::Interactor).to receive(:options=).
          with(option1: "a", option2: 123)

        evaluator.call(contents)
      end
    end
  end

  describe "#group" do
    context "no plugins in group" do
      let(:contents) { "group :w" }

      it "displays an error" do
        expect(::Guard::UI).to receive(:error).
          with("No Guard plugins found in the group 'w',"\
               " please add at least one.")

        evaluator.call(contents)
      end
    end

    context "group named :all" do
      let(:contents) { "group :all" }

      it "raises an error" do
        expect { evaluator.call(contents) }.
          to raise_error(
            Guard::Dsl::Error,
            /'all' is not an allowed group name!/)
      end
    end

    context 'group named "all"' do
      let(:contents) { "group 'all'" }

      it "raises an error" do
        expect { evaluator.call(contents) }.
          to raise_error(
            Guard::Dsl::Error,
            /'all' is not an allowed group name!/)
      end
    end

    context "with a valid guardfile" do
      let(:contents) { valid_guardfile_string }

      it "evaluates all groups" do
        expect(::Guard).to receive(:add_plugin).
          with(:pow,    watchers: [], callbacks: [], group: :default)

        expect(::Guard).to receive(:add_plugin).
          with(:test,   watchers: [], callbacks: [], group: :w)

        expect(::Guard).to receive(:add_plugin).
          with(:rspec,  watchers: [], callbacks: [], group: :x).twice

        expect(::Guard).to receive(:add_plugin).
          with(:less,   watchers: [], callbacks: [], group: :y)

        allow(Guard::Notifier).to receive(:add).with(:growl, silent: false)
        evaluator.call(contents)
      end
    end

    context "with multiple names" do
      let(:contents) { "group :foo, :bar do; end" }
      it "adds all given groups" do
        expect(::Guard).to receive(:add_group).with(:foo, {})
        expect(::Guard).to receive(:add_group).with(:bar, {})

        evaluator.call(contents)
      end
    end
  end

  describe "#guard" do
    context "with single-quoted name" do
      let(:contents) { 'guard \'test\'' }

      it "loads a guard specified as a quoted string from the DSL" do
        expect(::Guard).to receive(:add_plugin).
          with("test",  watchers: [], callbacks: [], group: :default)

        evaluator.call(contents)
      end
    end

    context "with double-quoted name" do
      let(:contents) { 'guard "test"' }

      it "loads a guard specified as a double quoted string from the DSL" do
        expect(::Guard).to receive(:add_plugin).
          with("test",  watchers: [], callbacks: [], group: :default)

        evaluator.call(contents)
      end
    end

    context "with symbol for name" do
      let(:contents) { "guard :test" }

      it "loads a guard specified as a symbol from the DSL" do
        expect(::Guard).to receive(:add_plugin).
          with(:test,  watchers: [], callbacks: [], group: :default)

        evaluator.call(contents)
      end
    end

    context "with name as symbol in parens" do
      let(:contents) { "guard(:test)" }

      it "adds the plugin" do
        expect(::Guard).to receive(:add_plugin).
          with(:test,  watchers: [], callbacks: [], group: :default)
        evaluator.call(contents)
      end
    end

    context "with options" do
      let(:contents) { 'guard \'test\', opt_a: 1, opt_b: \'fancy\'' }

      it "passes options to plugin" do
        options = {
          watchers: [],
          callbacks: [],
          opt_a: 1,
          opt_b: "fancy",
          group: :default
        }

        expect(::Guard).to receive(:add_plugin).with("test",  options)
        evaluator.call(contents)
      end
    end

    context "with groups" do
      let(:contents) { "group :foo do; group :bar do; guard :test; end; end" }

      it "adds plugin with group info" do
        expect(::Guard).to receive(:add_plugin).
          with(:test,  watchers: [], callbacks: [], group: :bar)

        evaluator.call(contents)
      end
    end

    context "with plugins in custom and default groups" do
      let(:contents) do
        "group :foo do; group :bar do; guard :test; end; end; guard :rspec"
      end

      it "assigns plugins to correct groups" do
        expect(::Guard).to receive(:add_plugin).
          with(:test,  watchers: [], callbacks: [], group: :bar)

        expect(::Guard).to receive(:add_plugin).
          with(:rspec,  watchers: [], callbacks: [], group: :default)

        evaluator.call(contents)
      end
    end
  end

  describe "#watch" do
    # TODO: this is testing too much
    context "with watchers" do
      let(:watcher_a) do
        instance_double("Guard::Watcher", pattern: "a", action: proc { "b" })
      end

      let(:watcher_c) do
        instance_double("Guard::Watcher", pattern: "c", action: nil)
      end

      let(:contents) do
        '
        guard :dummy do
           watch(\'a\') { \'b\' }
           watch(\'c\')
        end'
      end

      it "should receive watchers when specified" do
        call_params = {
          watchers: [anything, anything],
          callbacks: [],
          group: :default
        }

        expect(::Guard).to receive(:add_plugin).
          with(:dummy, call_params) do |_, options|
          expect(options[:watchers].size).to eq 2
          expect(options[:watchers][0].pattern).to eq "a"
          expect(options[:watchers][0].action.call).to eq proc { "b" }.call
          expect(options[:watchers][1].pattern).to eq "c"
          expect(options[:watchers][1].action).to be_nil
        end

        allow(Guard::Watcher).to receive(:new).with("a", anything).
          and_return(watcher_a)

        allow(Guard::Watcher).to receive(:new).with("c", nil).
          and_return(watcher_c)

        evaluator.call(contents)
      end
    end

    context "with watch in main scope" do
      let(:contents) { 'watch(\'a\')' }
      let(:watcher) do
        instance_double("Guard::Watcher", pattern: "a", action: nil)
      end

      it "should create an implicit no-op guard when outside a guard block" do
        plugin_options = {
          watchers: [anything],
          callbacks: [],
          group: :default
        }

        expect(::Guard).to receive(:add_plugin).
          with(:plugin, plugin_options) do |_, options|

          expect(options[:watchers].size).to eq 1
          expect(options[:watchers][0].pattern).to eq "a"
          expect(options[:watchers][0].action).to be_nil
        end

        allow(Guard::Watcher).to receive(:new).with("a", nil).
          and_return(watcher)

        evaluator.call(contents)
      end
    end
  end

  describe "#callback" do
    context "with " do
      let(:contents) do
        '
        guard :rspec do

          callback(:start_end) do |plugin, event, args|
            "#{plugin.title} executed \'#{event}\' hook with #{args}!"
          end

          callback(MyCustomCallback, [:start_begin, :run_all_begin])
        end'
      end

      it "creates callbacks for the guard" do
        class MyCustomCallback
          def self.call(_plugin, _event, _args)
            # do nothing
          end
        end

        params = {
          watchers: [],
          callbacks: [anything, anything],
          group: :default
        }

        expect(::Guard).to receive(:add_plugin).with(:rspec, params) do |_, opt|
          # TODO: this whole block is too verbose, tests too many things at
          # once and needs refactoring

          expect(opt[:callbacks].size).to eq 2

          callback_0 = opt[:callbacks][0]

          expect(callback_0[:events]).to eq :start_end

          plugin = instance_double("Guard::Plugin", title: "RSpec")
          result = callback_0[:listener].call(plugin, :start_end, "foo")

          expect(result).to eq 'RSpec executed \'start_end\' hook'\
            " with foo!"

          callback_1 = opt[:callbacks][1]
          expect(callback_1[:events]).to eq [:start_begin, :run_all_begin]
          expect(callback_1[:listener]).to eq MyCustomCallback
        end

        evaluator.call(contents)
      end
    end

    context "without a guard block" do
      let(:contents) do
        '
        callback(:start_end) do |plugin, event, args|
          "#{plugin} executed \'#{event}\' hook with #{args}!"
        end

        callback(MyCustomCallback, [:start_begin, :run_all_begin])'
      end

      it "fails" do
        expect { evaluator.call(contents) }.to raise_error(/guard block/i)
      end
    end
  end

  describe "#logger" do
    after do
      Guard::UI.options = {
        level: :info,
        template: ":time - :severity - :message",
        time_format: "%H:%M:%S"
      }
    end

    describe "options" do
      let(:contents) { "" }

      before do
        evaluator.call(contents)
      end

      subject { Guard::UI.options }

      context "with logger level :errror" do
        let(:contents) { "logger level: :error" }
        it { is_expected.to include("level" => :error) }
      end

      context "with logger level 'errror'" do
        let(:contents) { 'logger level: \'error\'' }
        it { is_expected.to include("level" => :error) }
      end

      context "with logger template" do
        let(:contents) { 'logger template: \':message - :severity\'' }
        it { is_expected.to include("template" => ":message - :severity") }
      end

      context "with a logger time format" do
        let(:contents) { 'logger time_format: \'%Y\'' }
        it { is_expected.to include("time_format" => "%Y") }
      end

      context "with a logger only filter from a symbol" do
        let(:contents) { "logger only: :cucumber" }
        it { is_expected.to include("only" => /cucumber/i) }
      end

      context "with logger only filter from a string" do
        let(:contents) { 'logger only: \'jasmine\'' }
        it { is_expected.to include("only" => /jasmine/i) }
      end

      context "with logger only filter from an array of symbols and string" do
        let(:contents) { 'logger only: [:rspec, \'cucumber\']' }
        it { is_expected.to include("only" => /rspec|cucumber/i) }
      end

      context "with logger except filter from a symbol" do
        let(:contents) { "logger except: :jasmine" }
        it { is_expected.to include("except" => /jasmine/i) }
      end

      context "with logger except filter from a string" do
        let(:contents) { 'logger except: \'jasmine\'' }
        it { is_expected.to include("except" => /jasmine/i) }
      end

      context "with logger except filter from array of symbols and string" do
        let(:contents) { 'logger except: [:rspec, \'cucumber\', :jasmine]' }
        it { is_expected.to include("except" => /rspec|cucumber|jasmine/i) }
      end
    end

    context "with invalid options" do
      context "for the log level" do
        let(:contents) { "logger level: :baz" }

        it "shows a warning" do
          expect(Guard::UI).to receive(:warning).
            with "Invalid log level `baz` ignored."\
            " Please use either :debug, :info, :warn or :error."

          evaluator.call(contents)
        end

        it "does not set the invalid value" do
          evaluator.call(contents)
          expect(Guard::UI.options).to include("level" => :info)
        end
      end

      context "when having both the :only and :except options" do
        let(:contents) { "logger only: :jasmine, except: :rspec" }

        it "shows a warning" do
          expect(Guard::UI).to receive(:warning).
            with "You cannot specify the logger options"\
            " :only and :except at the same time."
          evaluator.call(contents)
        end

        it "removes the options" do
          evaluator.call(contents)
          expect(Guard::UI.options[:only]).to be_nil
          expect(Guard::UI.options[:except]).to be_nil
        end
      end

    end
  end

  describe "#scope" do
    context "with any parameters" do
      let(:contents) { "scope plugins: [:foo, :bar]" }

      it "sets the guardfile's default scope" do
        expect(::Guard).to receive(:setup_scope).with(plugins: [:foo, :bar])
        evaluator.call(contents)
      end
    end
  end

  describe "#directories" do
    context "with valid directories" do
      let(:contents) { "directories %w(foo bar)" }
      before do
        allow(Dir).to receive(:exist?).with("foo").and_return(true)
        allow(Dir).to receive(:exist?).with("bar").and_return(true)
      end

      it "sets the watchdirs to given values" do
        expect(::Guard).to receive(:watchdirs=).with(%w(foo bar))
        evaluator.call(contents)
      end
    end

    context "with no parameters" do
      let(:contents) { "directories []" }

      it "sets the watchdirs to empty" do
        expect(::Guard).to receive(:watchdirs=).with([])
        evaluator.call(contents)
      end
    end

    context "with non-existing directory" do
      let(:contents) { "directories ['foo']" }

      before do
        allow(Dir).to receive(:exist?).with("foo").and_return(false)
      end

      it "fails with an error" do
        expect(::Guard).to_not receive(:watchdirs=)
        expect do
          evaluator.call(contents)
        end.to raise_error(RuntimeError, "Directory \"foo\" does not exist!")
      end
    end
  end

  private

  def valid_guardfile_string
    '
    notification :growl

    guard :pow

    group :w do
      guard :test
    end

    group :x, halt_on_fail: true do
      guard :rspec
      guard :rspec
    end

    group :y do
      guard :less
    end
    '
  end
end
