require 'spec_helper'

describe Guard::Hook do

  let(:listener) { double('listener').as_null_object }

  let(:fake_plugin) do
    Class.new(Guard::Guard) do
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

  before do
    stub_const 'Guard::Dummy', fake_plugin
    described_class.add_callback(listener, ::Guard::Dummy, :start_begin)
  end

  after { described_class.reset_callbacks! }

  describe '.add_callback' do
    it 'can add a single callback' do
      described_class.has_callback?(listener, ::Guard::Dummy, :start_begin).should be_true
    end

    it 'can add multiple callbacks' do
      described_class.add_callback(listener, ::Guard::Dummy, [:event1, :event2])
      described_class.has_callback?(listener, ::Guard::Dummy, :event1).should be_true
      described_class.has_callback?(listener, ::Guard::Dummy, :event2).should be_true
    end
  end

  describe '.notify' do
    it "sends :call to the given Guard class's callbacks" do
      listener.should_receive(:call).with(::Guard::Dummy, :start_begin, 'args')
      described_class.notify(::Guard::Dummy, :start_begin, 'args')
    end

    it 'runs only the given callbacks' do
      listener2 = double('listener2')
      described_class.add_callback(listener2, ::Guard::Dummy, :start_end)
      listener2.should_not_receive(:call).with(::Guard::Dummy, :start_end)
      described_class.notify(::Guard::Dummy, :start_begin)
    end

    it 'runs callbacks only for the guard given' do
      guard2_class = double('Guard::Dummy2').class
      described_class.add_callback(listener, guard2_class, :start_begin)
      listener.should_not_receive(:call).with(guard2_class, :start_begin)
      described_class.notify(::Guard::Dummy, :start_begin)
    end
  end

  describe '#hook' do
    let(:plugin) { ::Guard::Dummy.new }

    it 'notifies the hooks' do
      Guard::Hook.should_receive(:notify).with(::Guard::Dummy, :run_all_begin)
      Guard::Hook.should_receive(:notify).with(::Guard::Dummy, :run_all_end)
      plugin.run_all
    end

    it 'passes the hooks name' do
      Guard::Hook.should_receive(:notify).with(::Guard::Dummy, :my_hook)
      plugin.start
    end

    it 'accepts extra arguments' do
      Guard::Hook.should_receive(:notify).with(::Guard::Dummy, :stop_begin, 'args')
      Guard::Hook.should_receive(:notify).with(::Guard::Dummy, :special_sauce, 'first_arg', 'second_arg')
      plugin.stop
    end
  end

end
