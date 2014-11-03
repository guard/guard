require "guard/jobs/sleep"

RSpec.describe Guard::Jobs::Sleep do
  subject { described_class.new({}) }

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

    it "returns :stopped when put to background" do
      Thread.new do
        sleep 0.1
        subject.background
      end

      expect(subject.foreground).to eq(:stopped)
    end
  end

  describe "#background" do
    it "wakes up main thread" do
      status = "unknown"

      Thread.new do
        sleep 0.1
        subject.background
        status = Thread.main.status

        Thread.main.wakeup # to get "red" in TDD without hanging
      end

      subject.foreground
      expect(status).to eq("run")
    end
  end
end
