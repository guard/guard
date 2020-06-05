# frozen_string_literal: true

require "guard/engine"
require "guard/plugin"
require "guard/dsl"
require "guard/dsl_reader"

RSpec.describe Guard::Dsl, :stub_ui do
  include_context "with engine"

  let(:evaluator) do
    proc do |contents|
      described_class.new(engine).evaluate(contents, "", 1)
    end
  end

  subject { described_class.new(engine) }

  methods = %w[
    initialize guard notification interactor group watch callback
    ignore ignore! logger scope directories clearing
  ].map(&:to_sym)

  methods.each do |meth|
    describe "\##{meth} signature" do
      it "matches base signature" do
        expected = Guard::DslReader.instance_method(meth).arity

        expect(subject.method(meth).arity).to eq(expected)
      end
    end
  end

  describe "#ignore" do
    context "with ignore regexps" do
      let(:contents) { "ignore %r{^foo}, /bar/" }

      it "adds ignored regexps to the listener" do
        expect(session).to receive(:guardfile_ignore=).with([/^foo/, /bar/])

        evaluator.call(contents)
      end
    end

    context "with multiple ignore calls" do
      let(:contents) { "ignore(/foo/); ignore(/bar/)" }

      it "adds all ignored regexps to the listener" do
        expect(session).to receive(:guardfile_ignore=).with([/foo/]).once
        expect(session).to receive(:guardfile_ignore=).with([/bar/]).once

        evaluator.call(contents)
      end
    end
  end

  describe "#ignore!" do
    context "when ignoring only foo* and *bar*" do
      let(:contents) { "ignore! %r{^foo}, /bar/" }

      it "replaces listener regexps" do
        expect(session).to receive(:guardfile_ignore_bang=)
          .with([[/^foo/, /bar/]])

        evaluator.call(contents)
      end
    end

    context "when ignoring *.txt and *.zip and ignoring! only foo*" do
      let(:contents) { "ignore! %r{.txt$}, /.*\\.zip/\n ignore! %r{^foo}" }

      it "replaces listener ignores, but keeps ignore! ignores" do
        allow(session).to receive(:guardfile_ignore_bang=)
          .with([[/.txt$/, /.*\.zip/]])

        expect(session).to receive(:guardfile_ignore_bang=)
          .with([[/.txt$/, /.*\.zip/], [/^foo/]])

        evaluator.call(contents)
      end
    end
  end

  describe "#notification" do
    context "when notification" do
      let(:contents) { "notification :growl" }

      it "adds a notification to the notifier" do
        expect(session).to receive(:guardfile_notification=).with(growl: {})

        evaluator.call(contents)
      end
    end

    context "with multiple notifications" do
      let(:contents) do
        "notification :growl\nnotification :ruby_gntp, host: '192.168.1.5'"
      end

      it "adds multiple notifiers" do
        expect(session).to receive(:guardfile_notification=).with(growl: {})
        expect(session).to receive(:guardfile_notification=).with(
          ruby_gntp: { host: "192.168.1.5" }
        )

        evaluator.call(contents)
      end
    end
  end

  describe "#interactor" do
    context "with interactor :off" do
      let(:contents) { "interactor :off" }
      it "disables the interactions with :off" do
        expect(engine).to receive(:interactor=).with(:off)

        evaluator.call(contents)
      end
    end

    context "with interactor options" do
      let(:contents) { "interactor option1: 'a', option2: 123" }
      it "passes the options to the interactor" do
        expect(engine).to receive(:interactor=).with(option1: "a", option2: 123)

        evaluator.call(contents)
      end
    end
  end

  describe "#group" do
    context "no plugins in group" do
      let(:contents) { "group :w" }

      it "displays an error" do
        expect(::Guard::UI).to receive(:error)
          .with("No Guard plugins found in the group 'w',"\
               " please add at least one.")

        evaluator.call(contents)
      end
    end

    context "group named :all" do
      let(:contents) { "group :all" }

      it "raises an error" do
        expect { evaluator.call(contents) }
          .to raise_error(
            Guard::Dsl::Error,
            /'all' is not an allowed group name!/
          )
      end
    end

    context 'group named "all"' do
      let(:contents) { "group 'all'" }

      it "raises an error" do
        expect { evaluator.call(contents) }
          .to raise_error(
            Guard::Dsl::Error,
            /'all' is not an allowed group name!/
          )
      end
    end

    context "with a valid guardfile" do
      let(:contents) { valid_guardfile_string }

      it "evaluates all groups" do
        expect(groups).to receive(:add).with(:w, {})
        expect(groups).to receive(:add).with(:y, {})
        expect(groups).to receive(:add).with(:x, halt_on_fail: true)

        expect(plugins).to receive(:add)
          .with(:pow, watchers: [], callbacks: [], group: :default)

        expect(plugins).to receive(:add)
          .with(:test, watchers: [], callbacks: [], group: :w)

        expect(plugins).to receive(:add)
          .with(:rspec, watchers: [], callbacks: [], group: :x).twice

        expect(plugins).to receive(:add)
          .with(:less, watchers: [], callbacks: [], group: :y)

        expect(session).to receive(:guardfile_notification=).with(growl: {})
        evaluator.call(contents)
      end
    end

    context "with multiple names" do
      let(:contents) { "group :foo, :bar do; end" }
      it "adds all given groups" do
        expect(groups).to receive(:add).with(:foo, {})
        expect(groups).to receive(:add).with(:bar, {})

        evaluator.call(contents)
      end
    end
  end

  describe "#guard" do
    context "with single-quoted name" do
      let(:contents) { "guard 'test'" }

      it "loads a guard specified as a quoted string from the DSL" do
        expect(plugins).to receive(:add)
          .with("test", watchers: [], callbacks: [], group: :default)

        evaluator.call(contents)
      end
    end

    context "with double-quoted name" do
      let(:contents) { 'guard "test"' }

      it "loads a guard specified as a double quoted string from the DSL" do
        expect(plugins).to receive(:add)
          .with("test", watchers: [], callbacks: [], group: :default)

        evaluator.call(contents)
      end
    end

    context "with symbol for name" do
      let(:contents) { "guard :test" }

      it "loads a guard specified as a symbol from the DSL" do
        expect(plugins).to receive(:add)
          .with(:test, watchers: [], callbacks: [], group: :default)

        evaluator.call(contents)
      end
    end

    context "with name as symbol in parens" do
      let(:contents) { "guard(:test)" }

      it "adds the plugin" do
        expect(plugins).to receive(:add)
          .with(:test, watchers: [], callbacks: [], group: :default)
        evaluator.call(contents)
      end
    end

    context "with options" do
      let(:contents) { "guard 'test', opt_a: 1, opt_b: 'fancy'" }

      it "passes options to plugin" do
        options = {
          watchers: [],
          callbacks: [],
          opt_a: 1,
          opt_b: "fancy",
          group: :default
        }

        expect(plugins).to receive(:add).with("test", options)
        evaluator.call(contents)
      end
    end

    context "with groups" do
      let(:contents) { "group :foo do; group :bar do; guard :test; end; end" }

      it "adds plugin with group info" do
        expect(groups).to receive(:add).with(:foo, {})
        expect(groups).to receive(:add).with(:bar, {})
        expect(plugins).to receive(:add)
          .with(:test, watchers: [], callbacks: [], group: :bar)

        evaluator.call(contents)
      end
    end

    context "with plugins in custom and default groups" do
      let(:contents) do
        "group :foo do; group :bar do; guard :test; end; end; guard :rspec"
      end

      it "assigns plugins to correct groups" do
        expect(groups).to receive(:add).with(:foo, {})
        expect(groups).to receive(:add).with(:bar, {})

        expect(plugins).to receive(:add)
          .with(:test, watchers: [], callbacks: [], group: :bar)

        expect(plugins).to receive(:add)
          .with(:rspec, watchers: [], callbacks: [], group: :default)

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

        expect(plugins).to receive(:add)
          .with(:dummy, call_params) do |_, options|
          expect(options[:watchers].size).to eq 2
          expect(options[:watchers][0].pattern).to eq "a"
          expect(options[:watchers][0].action.call).to eq proc { "b" }.call
          expect(options[:watchers][1].pattern).to eq "c"
          expect(options[:watchers][1].action).to be_nil
        end

        allow(Guard::Watcher).to receive(:new).with("a", anything)
                                              .and_return(watcher_a)

        allow(Guard::Watcher).to receive(:new).with("c", nil)
                                              .and_return(watcher_c)

        evaluator.call(contents)
      end
    end

    context "with watch in main scope" do
      let(:contents) { "watch('a')" }
      let(:watcher) do
        instance_double("Guard::Watcher", pattern: "a", action: nil)
      end

      it "should create an implicit no-op guard when outside a guard block" do
        plugin_options = {
          watchers: [anything],
          callbacks: [],
          group: :default
        }

        expect(plugins).to receive(:add)
          .with(:plugin, plugin_options) do |_, options|
          expect(options[:watchers].size).to eq 1
          expect(options[:watchers][0].pattern).to eq "a"
          expect(options[:watchers][0].action).to be_nil
        end

        allow(Guard::Watcher).to receive(:new).with("a", nil)
                                              .and_return(watcher)

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

        expect(plugins).to receive(:add).with(:rspec, params) do |_, opt|
          # TODO: this whole block is too verbose, tests too many things at
          # once and needs refactoring

          expect(opt[:callbacks].size).to eq 2

          callback0 = opt[:callbacks][0]

          expect(callback0[:events]).to eq :start_end

          plugin = instance_double("Guard::Plugin", title: "RSpec")
          result = callback0[:listener].call(plugin, :start_end, "foo")

          expect(result).to eq "RSpec executed 'start_end' hook"\
            " with foo!"

          callback1 = opt[:callbacks][1]
          expect(callback1[:events]).to eq %i[start_begin run_all_begin]
          expect(callback1[:listener]).to eq MyCustomCallback
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
    before do
      allow(Guard::UI).to receive(:options).and_return({})
      allow(Guard::UI).to receive(:options=)
      allow(Guard::UI).to receive(:level=)
      allow(Guard::UI).to receive(:template=)
    end

    describe "options" do
      let(:contents) { "" }

      subject { Guard::UI }

      context "with logger level :error" do
        let(:contents) { "logger level: :error" }

        it do
          expect(Guard::UI).to receive(:level=).with(:error)

          evaluator.call(contents)
        end
      end

      context "with logger level 'error'" do
        let(:contents) { "logger level: 'error'" }

        it do
          expect(Guard::UI).to receive(:level=).with(:error)

          evaluator.call(contents)
        end
      end

      context "with logger template" do
        let(:contents) { "logger template: ':message - :severity'" }

        it do
          expect(Guard::UI).to receive(:template=).with(":message - :severity")

          evaluator.call(contents)
        end
      end

      context "with a logger time format" do
        let(:contents) { "logger time_format: '%Y'" }

        it do
          expect(Guard::UI.options).to receive(:merge!).with(time_format: "%Y")

          evaluator.call(contents)
        end
      end

      context "with a logger only filter from a symbol" do
        let(:contents) { "logger only: :cucumber" }

        it do
          expect(Guard::UI.options).to receive(:merge!).with(only: /cucumber/i)

          evaluator.call(contents)
        end
      end

      context "with logger only filter from a string" do
        let(:contents) { "logger only: 'jasmine'" }
        subject { Guard::UI.options }

        it do
          expect(Guard::UI.options).to receive(:merge!).with(only: /jasmine/i)

          evaluator.call(contents)
        end
      end

      context "with logger only filter from an array of symbols and string" do
        let(:contents) { "logger only: [:rspec, 'cucumber']" }

        it do
          expect(Guard::UI.options).to receive(:merge!).with(only: /rspec|cucumber/i)

          evaluator.call(contents)
        end
      end

      context "with logger except filter from a symbol" do
        let(:contents) { "logger except: :jasmine" }

        it do
          expect(Guard::UI.options).to receive(:merge!).with(except: /jasmine/i)

          evaluator.call(contents)
        end
      end

      context "with logger except filter from a string" do
        let(:contents) { "logger except: 'jasmine'" }

        it do
          expect(Guard::UI.options).to receive(:merge!).with(except: /jasmine/i)

          evaluator.call(contents)
        end
      end

      context "with logger except filter from array of symbols and string" do
        let(:contents) { "logger except: [:rspec, 'cucumber', :jasmine]" }

        it do
          expect(Guard::UI.options).to receive(:merge!).with(except: /rspec|cucumber|jasmine/i)

          evaluator.call(contents)
        end
      end
    end

    context "with invalid options" do
      context "for the log level" do
        let(:contents) { "logger level: :baz" }

        it "shows a warning" do
          expect(Guard::UI).to receive(:warning)
            .with "Invalid log level `baz` ignored."\
            " Please use either :debug, :info, :warn or :error."

          evaluator.call(contents)
        end

        it "does not set the invalid value" do
          expect(Guard::UI).not_to receive(:level=)

          evaluator.call(contents)
        end
      end

      context "when having both the :only and :except options" do
        let(:contents) { "logger only: :jasmine, except: :rspec" }

        it "shows a warning" do
          expect(Guard::UI).to receive(:warning)
            .with "You cannot specify the logger options"\
            " :only and :except at the same time."

          evaluator.call(contents)
        end

        it "removes the options" do
          expect(Guard::UI.options).to receive(:merge!).with({})

          evaluator.call(contents)
        end
      end
    end
  end

  describe "#scope" do
    context "with any parameters" do
      let(:contents) { "scope plugins: [:foo, :bar]" }

      it "sets the guardfile's default scope" do
        expect(session).to receive(:guardfile_scopes=).with(plugins: %i[foo bar])

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
        expect(session).to receive(:watchdirs=).with(%w[foo bar])
        evaluator.call(contents)
      end
    end

    context "with no parameters" do
      let(:contents) { "directories []" }

      it "sets the watchdirs to empty" do
        expect(session).to receive(:watchdirs=).with([])
        evaluator.call(contents)
      end
    end

    context "with non-existing directory" do
      let(:contents) { "directories ['foo']" }

      before do
        allow(Dir).to receive(:exist?).with("foo").and_return(false)
      end

      it "fails with an error" do
        expect(session).to_not receive(:watchdirs=)
        expect do
          evaluator.call(contents)
        end.to raise_error(Guard::Dsl::Error, /Directory "foo" does not exist!/)
      end
    end
  end

  describe "#clear" do
    context "with clear :off" do
      let(:contents) { "clearing :off" }
      it "disables clearing the screen after every task" do
        expect(session).to receive(:clearing).with(false)
        evaluator.call(contents)
      end
    end

    context "with clear :on" do
      let(:contents) { "clearing :on" }
      it "enabled clearing the screen after every task" do
        expect(session).to receive(:clearing).with(true)
        evaluator.call(contents)
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
