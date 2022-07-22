# frozen_string_literal: true

require "guard/jobs/sleep"

RSpec.describe Guard::Jobs::Sleep, :stub_ui do
  include_context "with engine"

  subject { described_class.new(engine) }

  describe "#foreground" do
    it "sleeps" do
      status = "unknown"

      Thread.new do
        sleep 0.1
        status = Thread.main.status
        subject.background
      end

      subject.foreground

      expect(status).to eq("sleep")
    end

    it "returns :continue when put to background" do
      Thread.new do
        sleep 0.1
        subject.background
      end

      expect(subject.foreground).to eq(:continue)
    end
  end

  describe "#background" do
    it "wakes up main thread" do
      status = "unknown"

      Thread.new do
        sleep 0.1 # give enough time for foreground to put main thread to sleep

        subject.background

        sleep 0.1 # cause test to fail every time (without busy loop below)

        status = Thread.main.status

        Thread.main.wakeup # to get "red" in TDD without hanging
      end

      subject.foreground # go to sleep

      # Keep main thread busy until above thread has a chance to get status
      begin
        value = 0
        Timeout.timeout(0.1) { loop { value += 1 } }
      rescue Timeout::Error
      end

      expect(status).to eq("run")
    end
  end
end
