require 'spec_helper'
require 'guard/plugin'

describe Guard::Plugin::Hooker do

  let(:listener) { double('listener').as_null_object }

  let(:fake_plugin) do
    Class.new(Guard::Plugin) do
      def start
        hook 'my_hook'
      end

      def run_all
        hook :begin
        hook :end
      end

      def stop
        hook :begin, 'args'
        hook 'special_sauce', 'first_arg', 'second_arg'
      end

      def run_on_modifications(paths)
        hook :begin
      end
    end
  end
  let(:dummy1) { fake_plugin.new }
  let(:dummy2) { fake_plugin.new }

  before do
    stub_const 'Guard::Dummy', fake_plugin
    described_class.add_callback(listener, dummy1, :start_begin)
  end

  after { described_class.reset_callbacks! }

  describe '.add_callback' do
    it 'can add a single callback' do
      expect(described_class.callbacks[[dummy1, :start_begin]].include?(listener)).to be_true
    end

    it 'can add a run_on_modifications callback' do
      described_class.add_callback(listener, dummy1, :run_on_modifications_begin)

      expect(described_class.callbacks[[dummy1, :run_on_modifications_begin]].include?(listener)).to be_true
    end

    it 'can add multiple callbacks' do
      described_class.add_callback(listener, dummy1, [:event1, :event2])

      expect(described_class.callbacks[[dummy1, :event1]].include?(listener)).to be_true
      expect(described_class.callbacks[[dummy1, :event2]].include?(listener)).to be_true
    end
  end

  describe '.notify' do
    it "sends :call to the given Guard class's callbacks" do
      expect(listener).to receive(:call).with(dummy1, :start_begin, 'args')

      described_class.notify(dummy1, :start_begin, 'args')
    end

    it "sends :call to the given Guard class's run_on_modifications callback" do
      expect(listener).to receive(:call).with(dummy1, :start_begin, 'args')

      described_class.notify(dummy1, :start_begin, 'args')
    end

    it 'runs only the given callbacks' do
      listener2 = double('listener2')
      described_class.add_callback(listener2, dummy1, :start_end)

      expect(listener2).to_not receive(:call).with(dummy1, :start_end)

      described_class.notify(dummy1, :start_begin)
    end

    it 'runs callbacks only for the guard given' do
      described_class.add_callback(listener, dummy2, :start_begin)

      expect(listener).to_not receive(:call).with(dummy2, :start_begin)

      described_class.notify(dummy1, :start_begin)
    end
  end

  describe '#hook' do
    it 'notifies the hooks' do
      expect(described_class).to receive(:notify).with(dummy1, :run_all_begin)
      expect(described_class).to receive(:notify).with(dummy1, :run_all_end)

      dummy1.run_all
    end

    it 'passes the hooks name' do
      expect(described_class).to receive(:notify).with(dummy1, :my_hook)

      dummy1.start
    end

    it 'accepts extra arguments' do
      expect(described_class).to receive(:notify).with(dummy1, :stop_begin, 'args')
      expect(described_class).to receive(:notify).with(dummy1, :special_sauce, 'first_arg', 'second_arg')

      dummy1.stop
    end
  end

end
