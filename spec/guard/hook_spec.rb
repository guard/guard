require 'spec_helper'

describe Guard::Hook do
  subject { Guard::Hook }

  class Guard::Dummy < Guard::Guard
    include Guard::Hook

    def run_all
      hook :begin
      hook :end
    end
  end

  let(:guard_class) { ::Guard::Dummy }
  let(:listener) { double('listener').as_null_object }

  context "--module methods--" do
    before { subject.add_callback(listener, guard_class, :start_begin) }

    after { subject.reset_callbacks! }

    describe ".add_callback" do
      it "can add a single callback" do
        subject.has_callback?(listener, guard_class, :start_begin).should be_true
      end

      it "can add multiple callbacks" do
        subject.add_callback(listener, guard_class, [:event1, :event2])
        subject.has_callback?(listener, guard_class, :event1).should be_true
        subject.has_callback?(listener, guard_class, :event2).should be_true
      end
    end

    describe ".notify" do
      it "sends :call to the given Guard class's callbacks" do
        listener.should_receive(:call).with(guard_class, :start_begin)
        subject.notify(guard_class, :start_begin)
      end

      it "runs only the given callbacks" do
        listener2 = double('listener2')
        subject.add_callback(listener2, guard_class, :start_end)
        listener2.should_not_receive(:call).with(guard_class, :start_end)
        subject.notify(guard_class, :start_begin)
      end

      it "runs callbacks only for the guard given" do
        guard2_class = double('Guard::Dummy2').class
        subject.add_callback(listener, guard2_class, :start_begin)
        listener.should_not_receive(:call).with(guard2_class, :start_begin)
        subject.notify(guard_class, :start_begin)
      end
    end
  end

  describe "#hook" do
    it "calls Guard::Hook.notify" do
      guard = guard_class.new
      Guard::Hook.should_receive(:notify).with(guard_class, :run_all_begin)
      Guard::Hook.should_receive(:notify).with(guard_class, :run_all_end)
      guard.run_all
    end

    it "if passed a string parameter, will use that for the hook name" do
      guard_class.class_eval do
        def start
          hook "my_hook"
        end
      end

      guard = guard_class.new
      Guard::Hook.should_receive(:notify).with(guard_class, :my_hook)
      guard.start
    end
  end

end
