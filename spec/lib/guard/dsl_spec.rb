require 'spec_helper'
require 'guard/plugin'

describe Guard::Dsl do

  let(:local_guardfile) { File.join(Dir.pwd, 'Guardfile') }
  let(:home_guardfile) { File.expand_path(File.join('~', '.Guardfile')) }
  let(:home_config) { File.expand_path(File.join('~', '.guard.rb')) }
  let(:guardfile_evaluator) { double('Guard::Guardfile::Evaluator') }
  before do
    stub_const 'Guard::Foo', Class.new(Guard::Plugin)
    stub_const 'Guard::Bar', Class.new(Guard::Plugin)
    stub_const 'Guard::Baz', Class.new(Guard::Plugin)
    allow(::Guard).to receive(:setup_interactor)
    ::Guard.setup
  end

  def self.disable_user_config
    before { allow(File).to receive(:exist?).with(home_config).and_return(false) }
  end

  describe '.evaluate_guardfile' do
    it 'displays a deprecation warning to the user' do
      expect(::Guard::UI).to receive(:deprecation).with(::Guard::Deprecator::EVALUATE_GUARDFILE_DEPRECATION)

      described_class.evaluate_guardfile
    end

    it 'delegates to Guard::Guardfile::Generator' do
      expect(Guard::Guardfile::Evaluator).to receive(:new).with(foo: 'bar') { guardfile_evaluator }
      expect(guardfile_evaluator).to receive(:evaluate_guardfile)

      described_class.evaluate_guardfile(foo: 'bar')
    end
  end

  describe '#ignore' do
    disable_user_config
    let(:listener) { double }

    it 'adds ignored regexps to the listener' do
      allow(::Guard).to receive(:listener) { listener }
      expect(::Guard.listener).to receive(:ignore).with([/^foo/,/bar/]) { listener }

      described_class.evaluate_guardfile(guardfile_contents: 'ignore %r{^foo}, /bar/')
    end
  end

  describe '#ignore!' do
    disable_user_config
    let(:listener) { double }

    it 'replaces ignored regexps in the listener' do
      allow(::Guard).to receive(:listener) { listener }
      expect(::Guard.listener).to receive(:ignore!).with([[/^foo/,/bar/]]) { listener }

      described_class.evaluate_guardfile(guardfile_contents: 'ignore! %r{^foo}, /bar/')
    end

    it 'replaces ignored regexps in the listener but keeps these setted by filter!' do
      allow(::Guard).to receive(:listener) { listener }
      allow(::Guard.listener).to receive(:ignore!)
      expect(::Guard.listener).to receive(:ignore!).with([[/.txt$/, /.*.zip/], [/^foo/]]) { listener }

      described_class.evaluate_guardfile(guardfile_contents: "filter! %r{.txt$}, /.*.zip/\n ignore! %r{^foo}")
    end
  end

  describe '#filter' do
    disable_user_config
    let(:listener) { double }

    it 'adds ignored regexps to the listener' do
      allow(::Guard).to receive(:listener) { listener }
      expect(::Guard.listener).to receive(:ignore).with([/.txt$/, /.*.zip/]) { listener }

      described_class.evaluate_guardfile(guardfile_contents: 'filter %r{.txt$}, /.*.zip/')
    end
  end

  describe '#filter!' do
    disable_user_config
    let(:listener) { double }

    it 'replaces ignored regexps in the listener' do
      allow(::Guard).to receive(:listener) { listener }
      expect(::Guard.listener).to receive(:ignore!).with([[/.txt$/, /.*.zip/]]) { listener }

      described_class.evaluate_guardfile(guardfile_contents: 'filter! %r{.txt$}, /.*.zip/')
    end

    it 'replaces ignored regexps in the listener but keeps these setted by ignore!' do
      allow(::Guard).to receive(:listener) { listener }
      allow(::Guard.listener).to receive(:ignore!)
      expect(::Guard.listener).to receive(:ignore!).with([[/^foo/], [/.txt$/, /.*.zip/]]) { listener }

      described_class.evaluate_guardfile(guardfile_contents: "ignore! %r{^foo}\n filter! %r{.txt$}, /.*.zip/")
    end
  end

  describe '#notification' do
    disable_user_config

    it 'adds a notification to the notifier' do
      expect(::Guard::Notifier).to receive(:add_notifier).with(:growl, { silent: false })
      described_class.evaluate_guardfile(guardfile_contents: 'notification :growl')
    end

    it 'adds multiple notification to the notifier' do
      expect(::Guard::Notifier).to receive(:add_notifier).with(:growl, { silent: false })
      expect(::Guard::Notifier).to receive(:add_notifier).with(:ruby_gntp, { host: '192.168.1.5', silent: false })
      described_class.evaluate_guardfile(guardfile_contents: "notification :growl\nnotification :ruby_gntp, host: '192.168.1.5'")
    end
  end

  describe '#interactor' do
    disable_user_config

    it 'disables the interactions with :off' do
      described_class.evaluate_guardfile(guardfile_contents: 'interactor :off')
      expect(Guard::Interactor.enabled).to be_falsey
    end

    it 'passes the options to the interactor' do
      described_class.evaluate_guardfile(guardfile_contents: 'interactor option1: \'a\', option2: 123')
      expect(Guard::Interactor.options).to include({ option1: 'a', option2: 123 })
    end
  end

  describe '#group' do
    disable_user_config

    context 'no plugins in group' do
      it 'displays an error' do
        expect(::Guard::UI).to receive(:error).with("No Guard plugins found in the group 'w', please add at least one.")

        described_class.evaluate_guardfile(guardfile_contents: guardfile_string_with_empty_group)
      end
    end

    context 'group named :all' do
      it 'raises an error' do
        expect { described_class.evaluate_guardfile(guardfile_contents: "group :all") }.to raise_error(ArgumentError, "'all' is not an allowed group name!")
      end
    end

    context 'group named "all"' do
      it 'raises an error' do
        expect { described_class.evaluate_guardfile(guardfile_contents: "group 'all'") }.to raise_error(ArgumentError, "'all' is not an allowed group name!")
      end
    end

    it 'evaluates all groups' do
      expect(::Guard).to receive(:add_plugin).with(:pow,   { watchers: [], callbacks: [], group: :default })
      expect(::Guard).to receive(:add_plugin).with(:test,  { watchers: [], callbacks: [], group: :w })
      expect(::Guard).to receive(:add_plugin).with(:rspec, { watchers: [], callbacks: [], group: :x }).twice
      expect(::Guard).to receive(:add_plugin).with(:less,  { watchers: [], callbacks: [], group: :y })

      described_class.evaluate_guardfile(guardfile_contents: valid_guardfile_string)
    end

    it 'accepts multiple names' do
      expect(::Guard).to receive(:add_group).with(:foo, {})
      expect(::Guard).to receive(:add_group).with(:bar, {})

      described_class.evaluate_guardfile(guardfile_contents: 'group :foo, :bar do; end')
    end
  end

  describe '#guard' do
    disable_user_config

    it 'loads a guard specified as a quoted string from the DSL' do
      expect(::Guard).to receive(:add_plugin).with('test', { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard \'test\'')
    end

    it 'loads a guard specified as a double quoted string from the DSL' do
      expect(::Guard).to receive(:add_plugin).with('test', { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard "test"')
    end

    it 'loads a guard specified as a symbol from the DSL' do
      expect(::Guard).to receive(:add_plugin).with(:test, { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard :test')
    end

    it 'loads a guard specified as a symbol and called with parens from the DSL' do
      expect(::Guard).to receive(:add_plugin).with(:test, { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard(:test)')
    end

    it 'receives options when specified, from normal arg' do
      expect(::Guard).to receive(:add_plugin).with('test', { watchers: [], callbacks: [], opt_a: 1, opt_b: 'fancy', group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard \'test\', opt_a: 1, opt_b: \'fancy\'')
    end

    it 'respects groups' do
      expect(::Guard).to receive(:add_plugin).with(:test, { watchers: [], callbacks: [], group: :bar })

      described_class.evaluate_guardfile(guardfile_contents: 'group :foo do; group :bar do; guard :test; end; end')
    end

    it 'uses :default group by default' do
      expect(::Guard).to receive(:add_plugin).with(:test, { watchers: [], callbacks: [], group: :bar })
      expect(::Guard).to receive(:add_plugin).with(:rspec, { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'group :foo do; group :bar do; guard :test; end; end; guard :rspec')
    end
  end

  describe '#watch' do
    disable_user_config

    it 'should receive watchers when specified' do
      expect(::Guard).to receive(:add_plugin).with(:dummy, { watchers: [anything, anything], callbacks: [], group: :default }) do |_, options|
        expect(options[:watchers].size).to eq 2
        expect(options[:watchers][0].pattern).to eq 'a'
        expect(options[:watchers][0].action.call).to eq proc { 'b' }.call
        expect(options[:watchers][1].pattern).to eq 'c'
        expect(options[:watchers][1].action).to be_nil
      end
      described_class.evaluate_guardfile(guardfile_contents: '
      guard :dummy do
         watch(\'a\') { \'b\' }
         watch(\'c\')
      end')
    end

    it 'should create an implicit no-op guard when outside a guard block' do
      expect(::Guard).to receive(:add_plugin).with(:plugin, { watchers: [anything], callbacks: [], group: :default }) do |_, options|
        expect(options[:watchers].size).to eq 1
        expect(options[:watchers][0].pattern).to eq 'a'
        expect(options[:watchers][0].action).to be_nil
      end

      described_class.evaluate_guardfile(guardfile_contents: 'watch(\'a\')')
    end
  end

  describe '#callback' do
    it 'creates callbacks for the guard' do
      class MyCustomCallback
        def self.call(plugin, event, args)
          # do nothing
        end
      end

      expect(::Guard).to receive(:add_plugin).with(:rspec, { watchers: [], callbacks: [anything, anything], group: :default }) do |_, options|
        expect(options[:callbacks].size).to eq 2
        expect(options[:callbacks][0][:events]).to eq :start_end
        expect(options[:callbacks][0][:listener].call(Guard::RSpec, :start_end, 'foo')).to eq 'Guard::RSpec executed \'start_end\' hook with foo!'
        expect(options[:callbacks][1][:events]).to eq [:start_begin, :run_all_begin]
        expect(options[:callbacks][1][:listener]).to eq MyCustomCallback
      end

      described_class.evaluate_guardfile(guardfile_contents: '
        guard :rspec do
          callback(:start_end) { |plugin, event, args| "#{plugin} executed \'#{event}\' hook with #{args}!" }
          callback(MyCustomCallback, [:start_begin, :run_all_begin])
        end')
    end

    it 'should require a guard block' do
      expect {
        described_class.evaluate_guardfile(guardfile_contents: '
          callback(:start_end) { |plugin, event, args| "#{plugin} executed \'#{event}\' hook with #{args}!" }
          callback(MyCustomCallback, [:start_begin, :run_all_begin])')
      }.to raise_error(/guard block/i)
    end
  end

  describe '#logger' do
    after { Guard::UI.options = { level: :info, template: ':time - :severity - :message', time_format: '%H:%M:%S' } }

    context 'with valid options' do
      it 'sets the logger log level' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger level: :error')
        expect(Guard::UI.options[:level]).to eq :error
      end

      it 'sets the logger log level and convert to a symbol' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger level: \'error\'')
        expect(Guard::UI.options[:level]).to eq :error
      end

      it 'sets the logger template' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger template: \':message - :severity\'')
        expect(Guard::UI.options[:template]).to eq ':message - :severity'
      end

      it 'sets the logger time format' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger time_format: \'%Y\'')
        expect(Guard::UI.options[:time_format]).to eq '%Y'
      end

      it 'sets the logger only filter from a symbol' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger only: :cucumber')
        expect(Guard::UI.options[:only]).to eq(/cucumber/i)
      end

      it 'sets the logger only filter from a string' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger only: \'jasmine\'')
        expect(Guard::UI.options[:only]).to eq(/jasmine/i)
      end

      it 'sets the logger only filter from an array of symbols and string' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger only: [:rspec, \'cucumber\']')
        expect(Guard::UI.options[:only]).to eq(/rspec|cucumber/i)
      end

      it 'sets the logger except filter from a symbol' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger except: :jasmine')
        expect(Guard::UI.options[:except]).to eq(/jasmine/i)
      end

      it 'sets the logger except filter from a string' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger except: \'jasmine\'')
        expect(Guard::UI.options[:except]).to eq(/jasmine/i)
      end

      it 'sets the logger except filter from an array of symbols and string' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger except: [:rspec, \'cucumber\', :jasmine]')
        expect(Guard::UI.options[:except]).to eq(/rspec|cucumber|jasmine/i)
      end
    end

    context 'with invalid options' do
      context 'for the log level' do
        it 'shows a warning' do
          expect(Guard::UI).to receive(:warning).with 'Invalid log level `baz` ignored. Please use either :debug, :info, :warn or :error.'
          described_class.evaluate_guardfile(guardfile_contents: 'logger level: :baz')
        end

        it 'does not set the invalid value' do
          described_class.evaluate_guardfile(guardfile_contents: 'logger level: :baz')
          expect(Guard::UI.options[:level]).to eq :info
        end
      end

      context 'when having both the :only and :except options' do
        it 'shows a warning' do
          expect(Guard::UI).to receive(:warning).with 'You cannot specify the logger options :only and :except at the same time.'
          described_class.evaluate_guardfile(guardfile_contents: 'logger only: :jasmine, except: :rspec')
        end

        it 'removes the options' do
          described_class.evaluate_guardfile(guardfile_contents: 'logger only: :jasmine, except: :rspec')
          expect(Guard::UI.options[:only]).to be_nil
          expect(Guard::UI.options[:except]).to be_nil
        end
      end

    end
  end

  describe '#scope' do
    before do
      ::Guard.add_plugin(:foo)
      ::Guard.add_plugin(:bar)
      ::Guard.add_plugin(:baz)
      ::Guard.setup_scope(plugins: nil, groups: nil)
    end

    it 'does use the DSL scope plugin' do
      described_class.evaluate_guardfile(guardfile_contents: 'scope plugin: :baz')
      expect(::Guard.scope[:plugins]).to eq [::Guard.plugin(:baz)]
      ::Guard.setup_scope(plugins: [], groups: [])
      expect(::Guard.scope[:plugins]).to eq [::Guard.plugin(:baz)]
    end

    it 'does use the DSL scope plugins' do
      described_class.evaluate_guardfile(guardfile_contents: 'scope plugins: [:foo, :bar]')
      expect(::Guard.scope[:plugins]).to eq [::Guard.plugin(:foo), ::Guard.plugin(:bar)]
    end

    it 'does use the DSL scope group' do
      described_class.evaluate_guardfile(guardfile_contents: 'scope group: :baz')
      expect(::Guard.scope[:groups]).to eq ::Guard.groups(:baz)
    end

    it 'does use the DSL scope groups' do
      described_class.evaluate_guardfile(guardfile_contents: 'scope groups: [:foo, :bar]')
      expect(::Guard.scope[:groups]).to eq [::Guard.group(:foo), ::Guard.group(:bar)]
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

  def guardfile_string_with_empty_group
    'group :w'
  end
end
