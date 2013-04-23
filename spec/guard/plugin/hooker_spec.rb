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
      described_class.has_callback?(listener, dummy1, :start_begin).should be_true
    end

    it 'can add multiple callbacks' do
      described_class.add_callback(listener, dummy1, [:event1, :event2])
      described_class.has_callback?(listener, dummy1, :event1).should be_true
      described_class.has_callback?(listener, dummy1, :event2).should be_true
    end
  end

  describe '.notify' do
    it "sends :call to the given Guard class's callbacks" do
      listener.should_receive(:call).with(dummy1, :start_begin, 'args')
      described_class.notify(dummy1, :start_begin, 'args')
    end

    it 'runs only the given callbacks' do
      listener2 = double('listener2')
      described_class.add_callback(listener2, dummy1, :start_end)
      listener2.should_not_receive(:call).with(dummy1, :start_end)
      described_class.notify(dummy1, :start_begin)
    end

    it 'runs callbacks only for the guard given' do
      described_class.add_callback(listener, dummy2, :start_begin)
      listener.should_not_receive(:call).with(dummy2, :start_begin)
      described_class.notify(dummy1, :start_begin)
    end
  end

  describe '#hook' do
    it 'notifies the hooks' do
      described_class.should_receive(:notify).with(dummy1, :run_all_begin)
      described_class.should_receive(:notify).with(dummy1, :run_all_end)
      dummy1.run_all
    end

    it 'passes the hooks name' do
      described_class.should_receive(:notify).with(dummy1, :my_hook)
      dummy1.start
    end

    it 'accepts extra arguments' do
      described_class.should_receive(:notify).with(dummy1, :stop_begin, 'args')
      described_class.should_receive(:notify).with(dummy1, :special_sauce, 'first_arg', 'second_arg')
      dummy1.stop
    end
  end

end
