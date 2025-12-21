# frozen_string_literal: true

require "async"
require "async/condition"
require "guard/jobs/sleep"

RSpec.describe Guard::Jobs::Sleep, :stub_ui, :async do
  include_context "with engine"

  subject { described_class.new(engine) }

  describe "#foreground" do
    it "suspends until signaled" do
      foreground_completed = false

      foreground_task = async_task do
        subject.foreground
        foreground_completed = true
      end

      # Give foreground task time to start waiting
      sleep 0.01
      # Task should still be running (waiting on condition)
      expect(foreground_completed).to be false
      subject.background

      foreground_task.wait
      expect(foreground_completed).to be true
    end

    it "returns :continue when put to background" do
      result = nil

      foreground_task = async_task do
        result = subject.foreground
      end

      sleep 0.01
      subject.background

      foreground_task.wait
      expect(result).to eq(:continue)
    end
  end

  describe "#background" do
    it "wakes up the foreground task" do
      foreground_status_after_background = nil

      foreground_task = async_task do
        subject.foreground
        foreground_status_after_background = :awake
      end

      sleep 0.01
      subject.background

      foreground_task.wait
      expect(foreground_status_after_background).to eq(:awake)
    end
  end

  describe "#handle_interrupt" do
    it "signals exit" do
      result = nil

      foreground_task = async_task do
        result = subject.foreground
      end

      sleep 0.01
      subject.handle_interrupt

      foreground_task.wait
      expect(result).to eq(:exit)
    end
  end
end
