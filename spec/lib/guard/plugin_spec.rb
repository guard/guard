# frozen_string_literal: true
require 'guard/plugin'

require 'guard/watcher'

RSpec.describe Guard::Plugin do
  let(:default) { instance_double('Guard::Group') }
  let(:test) { instance_double('Guard::Group') }

  let(:session) { instance_double('Guard::Internals::Session') }
  let(:groups) { instance_double('Guard::Internals::Groups') }
  let(:state) { instance_double('Guard::Internals::State') }

  before do
    allow(groups).to receive(:add).with(:default).and_return(default)
    allow(groups).to receive(:add).with(:test).and_return(test)

    allow(session).to receive(:groups).and_return(groups)
    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)
  end

  # TODO: this should already be done in spec_helper!
  after do
    klass = described_class
    klass.instance_variables.each do |var|
      klass.instance_variable_set(var, nil)
    end
  end

  describe '#initialize' do
    it 'assigns the defined watchers' do
      watchers = [double('foo')]
      expect(Guard::Plugin.new(watchers: watchers).watchers).to eq watchers
    end

    it 'assigns the defined options' do
      options = { a: 1, b: 2 }
      expect(Guard::Plugin.new(options).options).to eq options
    end

    context 'with a group in the options' do
      it 'assigns the given group' do
        expect(Guard::Plugin.new(group: :test).group).to eq test
      end
    end

    context 'without a group in the options' do
      it 'assigns a default group' do
        allow(groups).to receive(:add).with(:default).and_return(default)
        expect(Guard::Plugin.new.group).to eq default
      end
    end

    context 'with a callback' do
      it 'adds the callback' do
        block = instance_double(Proc)
        events = [:start_begin, :start_end]
        callbacks = [{ events: events, listener: block }]
        Guard::Plugin.new(callbacks: callbacks)
        expect(Guard::Plugin.callbacks.first[0][0].callbacks).to eq(callbacks)
      end
    end
  end

  context 'with a plugin instance' do
    subject do
      module Guard
        class DuMmy < Guard::Plugin
        end
      end
      Guard::DuMmy
    end

    after do
      Guard.send(:remove_const, :DuMmy)
    end

    describe '.non_namespaced_classname' do
      it 'remove the Guard:: namespace' do
        expect(subject.non_namespaced_classname).to eq 'DuMmy'
      end
    end

    describe '.non_namespaced_name' do
      it 'remove the Guard:: namespace and downcase' do
        expect(subject.non_namespaced_name).to eq 'dummy'
      end
    end

    describe '.template' do
      before do
        allow(File).to receive(:read)
      end

      it 'reads the default template' do
        expect(File).to receive(:read).
          with('/guard-dummy/lib/guard/dummy/templates/Guardfile') { true }

        subject.template('/guard-dummy')
      end
    end

    describe '#name' do
      it 'outputs the short plugin name' do
        expect(subject.new.name).to eq 'dummy'
      end
    end

    describe '#title' do
      it 'outputs the plugin title' do
        expect(subject.new.title).to eq 'DuMmy'
      end
    end

    describe '#to_s' do
      let(:default) { instance_double('Guard::Group', name: :default) }

      it 'output the short plugin name' do
        expect(subject.new.to_s).
          to match(/#<Guard::DuMmy @name=dummy .*>/)
      end
    end
  end

  let(:listener) { instance_double(Proc, call: nil) }

  describe '.add_callback' do
    let(:foo) { double('foo plugin') }

    it 'can add a run_on_modifications callback' do
      described_class.add_callback(
        listener,
        foo,
        :run_on_modifications_begin
      )

      result = described_class.callbacks[[foo, :run_on_modifications_begin]]
      expect(result).to include(listener)
    end

    it 'can add multiple callbacks' do
      described_class.add_callback(listener, foo, [:event1, :event2])

      result = described_class.callbacks[[foo, :event1]]
      expect(result).to include(listener)

      result = described_class.callbacks[[foo, :event2]]
      expect(result).to include(listener)
    end
  end

  describe '.notify' do
    let(:foo) { double('foo plugin') }
    let(:bar) { double('bar plugin') }

    before do
      described_class.add_callback(listener, foo, :start_begin)
    end

    it "sends :call to the given Guard class's start_begin callback" do
      expect(listener).to receive(:call).with(foo, :start_begin, 'args')
      described_class.notify(foo, :start_begin, 'args')
    end

    it "sends :call to the given Guard class's start_begin callback" do
      expect(listener).to receive(:call).with(foo, :start_begin, 'args')
      described_class.notify(foo, :start_begin, 'args')
    end

    it 'runs only the given callbacks' do
      listener2 = double('listener2')
      described_class.add_callback(listener2, foo, :start_end)
      expect(listener2).to_not receive(:call).with(foo, :start_end)
      described_class.notify(foo, :start_begin)
    end

    it 'runs callbacks only for the guard given' do
      described_class.add_callback(listener, bar, :start_begin)
      expect(listener).to_not receive(:call).with(bar, :start_begin)
      described_class.notify(foo, :start_begin)
    end
  end

  describe '#hook' do
    let(:foo) { double('foo plugin') }

    before do
      described_class.add_callback(listener, foo, :start_begin)
    end

    it 'notifies the hooks' do
      class Foo < described_class
        def run_all
          hook :begin
          hook :end
        end
      end

      foo = Foo.new
      expect(described_class).to receive(:notify).with(foo, :run_all_begin)
      expect(described_class).to receive(:notify).with(foo, :run_all_end)
      foo.run_all
    end

    it 'passes the hooks name' do
      class Foo < described_class
        def start
          hook 'my_hook'
        end
      end

      foo = Foo.new
      expect(described_class).to receive(:notify).with(foo, :my_hook)
      foo.start
    end

    it 'accepts extra arguments' do
      class Foo < described_class
        def stop
          hook :begin, 'args'
          hook 'special_sauce', 'first_arg', 'second_arg'
        end
      end
      foo = Foo.new

      expect(described_class).to receive(:notify).
        with(foo, :stop_begin, 'args')

      expect(described_class).to receive(:notify).
        with(foo, :special_sauce, 'first_arg', 'second_arg')

      foo.stop
    end
  end
end
