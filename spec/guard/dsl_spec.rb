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
    ::Guard.stub(:setup_interactor)
    ::Guard.setup
  end

  def self.disable_user_config
    before { File.stub(:exist?).with(home_config) { false } }
  end

  describe '.evaluate_guardfile' do
    it 'displays a deprecation warning to the user' do
      ::Guard::UI.should_receive(:deprecation).with(::Guard::Deprecator::EVALUATE_GUARDFILE_DEPRECATION)

      described_class.evaluate_guardfile
    end

    it 'delegates to Guard::Guardfile::Generator' do
      Guard::Guardfile::Evaluator.should_receive(:new).with(foo: 'bar') { guardfile_evaluator }
      guardfile_evaluator.should_receive(:evaluate_guardfile)

      described_class.evaluate_guardfile(foo: 'bar')
    end
  end

  describe '#ignore_paths' do
    disable_user_config

    it 'adds the paths to the listener\'s ignore_paths' do
      ::Guard::UI.should_receive(:deprecation).with(Guard::Deprecator::DSL_METHOD_IGNORE_PATHS_DEPRECATION)

      described_class.evaluate_guardfile(guardfile_contents: 'ignore_paths \'foo\', \'bar\'')
    end
  end

  describe '#ignore' do
    disable_user_config
    let(:listener) { double }

    it 'add ignored regexps to the listener' do
      ::Guard.stub(:listener) { listener }
      ::Guard.listener.should_receive(:ignore).with(/^foo/,/bar/) { listener }
      ::Guard.should_receive(:listener=).with(listener)

      described_class.evaluate_guardfile(guardfile_contents: 'ignore %r{^foo}, /bar/')
    end
  end

  describe '#ignore!' do
    disable_user_config
    let(:listener) { double }

    it 'replace ignored regexps in the listener' do
      ::Guard.stub(:listener) { listener }
      ::Guard.listener.should_receive(:ignore!).with(/^foo/,/bar/) { listener }
      ::Guard.should_receive(:listener=).with(listener)

      described_class.evaluate_guardfile(guardfile_contents: 'ignore! %r{^foo}, /bar/')
    end
  end

  describe '#filter' do
    disable_user_config
    let(:listener) { double }

    it 'add ignored regexps to the listener' do
      ::Guard.stub(:listener) { listener }
      ::Guard.listener.should_receive(:filter).with(/.txt$/, /.*.zip/) { listener }
      ::Guard.should_receive(:listener=).with(listener)

      described_class.evaluate_guardfile(guardfile_contents: 'filter %r{.txt$}, /.*.zip/')
    end
  end

  describe '#filter!' do
    disable_user_config
    let(:listener) { double }

    it 'replace ignored regexps in the listener' do
      ::Guard.stub(:listener) { listener }
      ::Guard.listener.should_receive(:filter!).with(/.txt$/, /.*.zip/) { listener }
      ::Guard.should_receive(:listener=).with(listener)

      described_class.evaluate_guardfile(guardfile_contents: 'filter! %r{.txt$}, /.*.zip/')
    end
  end

  describe '#notification' do
    disable_user_config

    it 'adds a notification to the notifier' do
      ::Guard::Notifier.should_receive(:add_notifier).with(:growl, { silent: false })
      described_class.evaluate_guardfile(guardfile_contents: 'notification :growl')
    end

    it 'adds multiple notification to the notifier' do
      ::Guard::Notifier.should_receive(:add_notifier).with(:growl, { silent: false })
      ::Guard::Notifier.should_receive(:add_notifier).with(:ruby_gntp, { host: '192.168.1.5', silent: false })
      described_class.evaluate_guardfile(guardfile_contents: "notification :growl\nnotification :ruby_gntp, host: '192.168.1.5'")
    end
  end

  describe '#interactor' do
    disable_user_config

    it 'disables the interactions with :off' do
      ::Guard::UI.should_not_receive(:deprecation).with(Guard::Deprecator::DSL_METHOD_INTERACTOR_DEPRECATION)
      described_class.evaluate_guardfile(guardfile_contents: 'interactor :off')
      Guard::Interactor.enabled.should be_false
    end

    it 'shows a deprecation for symbols other than :off' do
      ::Guard::UI.should_receive(:deprecation).with(Guard::Deprecator::DSL_METHOD_INTERACTOR_DEPRECATION)
      described_class.evaluate_guardfile(guardfile_contents: 'interactor :coolline')
    end

    it 'passes the options to the interactor' do
      ::Guard::UI.should_not_receive(:deprecation).with(Guard::Deprecator::DSL_METHOD_INTERACTOR_DEPRECATION)
      described_class.evaluate_guardfile(guardfile_contents: 'interactor option1: \'a\', option2: 123')
      Guard::Interactor.options.should include({ option1: 'a', option2: 123 })
    end
  end

  describe '#group' do
    disable_user_config

    context 'no plugins in group' do
      it 'displays an error' do
        ::Guard::UI.should_receive(:error).with("No Guard plugins found in the group 'w', please add at least one.")

        described_class.evaluate_guardfile(guardfile_contents: guardfile_string_with_empty_group)
      end
    end

    it 'evaluates all groups' do
      ::Guard.should_receive(:add_plugin).with(:pow,   { watchers: [], callbacks: [], group: :default })
      ::Guard.should_receive(:add_plugin).with(:test,  { watchers: [], callbacks: [], group: :w })
      ::Guard.should_receive(:add_plugin).with(:rspec, { watchers: [], callbacks: [], group: :x })
      ::Guard.should_receive(:add_plugin).with(:ronn,  { watchers: [], callbacks: [], group: :x })
      ::Guard.should_receive(:add_plugin).with(:less,  { watchers: [], callbacks: [], group: :y })

      described_class.evaluate_guardfile(guardfile_contents: valid_guardfile_string)
    end
  end

  describe '#guard' do
    disable_user_config

    it 'loads a guard specified as a quoted string from the DSL' do
      ::Guard.should_receive(:add_plugin).with('test', { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard \'test\'')
    end

    it 'loads a guard specified as a double quoted string from the DSL' do
      ::Guard.should_receive(:add_plugin).with('test', { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard "test"')
    end

    it 'loads a guard specified as a symbol from the DSL' do
      ::Guard.should_receive(:add_plugin).with(:test, { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard :test')
    end

    it 'loads a guard specified as a symbol and called with parens from the DSL' do
      ::Guard.should_receive(:add_plugin).with(:test, { watchers: [], callbacks: [], group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard(:test)')
    end

    it 'receives options when specified, from normal arg' do
      ::Guard.should_receive(:add_plugin).with('test', { watchers: [], callbacks: [], opt_a: 1, opt_b: 'fancy', group: :default })

      described_class.evaluate_guardfile(guardfile_contents: 'guard \'test\', opt_a: 1, opt_b: \'fancy\'')
    end
  end

  describe '#watch' do
    disable_user_config

    it 'should receive watchers when specified' do
      ::Guard.should_receive(:add_plugin).with(:dummy, { watchers: [anything, anything], callbacks: [], group: :default }) do |_, options|
        options[:watchers].size.should eq 2
        options[:watchers][0].pattern.should eq 'a'
        options[:watchers][0].action.call.should eq proc { 'b' }.call
        options[:watchers][1].pattern.should eq 'c'
        options[:watchers][1].action.should be_nil
      end
      described_class.evaluate_guardfile(guardfile_contents: '
      guard :dummy do
         watch(\'a\') { \'b\' }
         watch(\'c\')
      end')
    end
  end

  describe '#callback' do
    it 'creates callbacks for the guard' do
      class MyCustomCallback
        def self.call(plugin, event, args)
          # do nothing
        end
      end

      ::Guard.should_receive(:add_plugin).with(:dummy, { watchers: [], callbacks: [anything, anything], group: :default }) do |_, options|
        options[:callbacks].should have(2).items
        options[:callbacks][0][:events].should    eq :start_end
        options[:callbacks][0][:listener].call(Guard::Dummy, :start_end, 'foo').should eq 'Guard::Dummy executed \'start_end\' hook with foo!'
        options[:callbacks][1][:events].should eq [:start_begin, :run_all_begin]
        options[:callbacks][1][:listener].should eq MyCustomCallback
      end

      described_class.evaluate_guardfile(guardfile_contents: '
        guard :dummy do
          callback(:start_end) { |plugin, event, args| "#{plugin} executed \'#{event}\' hook with #{args}!" }
          callback(MyCustomCallback, [:start_begin, :run_all_begin])
        end')
    end
  end

  describe '#logger' do
    after { Guard::UI.options = { level: :info, template: ':time - :severity - :message', time_format: '%H:%M:%S' } }

    context 'with valid options' do
      it 'sets the logger log level' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger level: :error')
        Guard::UI.options.level.should eq :error
      end

      it 'sets the logger log level and convert to a symbol' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger level: \'error\'')
        Guard::UI.options.level.should eq :error
      end

      it 'sets the logger template' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger template: \':message - :severity\'')
        Guard::UI.options.template.should eq ':message - :severity'
      end

      it 'sets the logger time format' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger time_format: \'%Y\'')
        Guard::UI.options.time_format.should eq '%Y'
      end

      it 'sets the logger only filter from a symbol' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger only: :cucumber')
        Guard::UI.options.only.should eq(/cucumber/i)
      end

      it 'sets the logger only filter from a string' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger only: \'jasmine\'')
        Guard::UI.options.only.should eq(/jasmine/i)
      end

      it 'sets the logger only filter from an array of symbols and string' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger only: [:rspec, \'cucumber\']')
        Guard::UI.options.only.should eq(/rspec|cucumber/i)
      end

      it 'sets the logger except filter from a symbol' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger except: :jasmine')
        Guard::UI.options.except.should eq(/jasmine/i)
      end

      it 'sets the logger except filter from a string' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger except: \'jasmine\'')
        Guard::UI.options.except.should eq(/jasmine/i)
      end

      it 'sets the logger except filter from an array of symbols and string' do
        described_class.evaluate_guardfile(guardfile_contents: 'logger except: [:rspec, \'cucumber\', :jasmine]')
        Guard::UI.options.except.should eq(/rspec|cucumber|jasmine/i)
      end
    end

    context 'with invalid options' do
      context 'for the log level' do
        it 'shows a warning' do
          Guard::UI.should_receive(:warning).with 'Invalid log level `baz` ignored. Please use either :debug, :info, :warn or :error.'
          described_class.evaluate_guardfile(guardfile_contents: 'logger level: :baz')
        end

        it 'does not set the invalid value' do
          described_class.evaluate_guardfile(guardfile_contents: 'logger level: :baz')
          Guard::UI.options.level.should eq :info
        end
      end

      context 'when having both the :only and :except options' do
        it 'shows a warning' do
          Guard::UI.should_receive(:warning).with 'You cannot specify the logger options :only and :except at the same time.'
          described_class.evaluate_guardfile(guardfile_contents: 'logger only: :jasmine, except: :rspec')
        end

        it 'removes the options' do
          described_class.evaluate_guardfile(guardfile_contents: 'logger only: :jasmine, except: :rspec')
          Guard::UI.options.only.should be_nil
          Guard::UI.options.except.should be_nil
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
      ::Guard.scope[:plugins].should eq [::Guard.plugin(:baz)]
      ::Guard.setup_scope(plugins: [], groups: [])
      ::Guard.scope[:plugins].should eq [::Guard.plugin(:baz)]
    end

    it 'does use the DSL scope plugins' do
      described_class.evaluate_guardfile(guardfile_contents: 'scope plugins: [:foo, :bar]')
      ::Guard.scope[:plugins].should eq [::Guard.plugin(:foo), ::Guard.plugin(:bar)]
    end

    it 'does use the DSL scope group' do
      described_class.evaluate_guardfile(guardfile_contents: 'scope group: :baz')
      ::Guard.scope[:groups].should eq [::Guard.groups(:baz)]
    end

    it 'does use the DSL scope groups' do
      described_class.evaluate_guardfile(guardfile_contents: 'scope groups: [:foo, :bar]')
      ::Guard.scope[:groups].should eq [::Guard.groups(:foo), ::Guard.groups(:bar)]
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
      guard :ronn
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
