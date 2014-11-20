require "guard/notifiers/file_notifier"

RSpec.describe Guard::Notifier::FileNotifier do
  let(:notifier) { described_class.new }

  describe ".available?" do
    it "returns true if there is a file in options" do
      expect(described_class).to be_available(path: ".guard_result")
    end

    it "returns false if there is no path in options" do
      expect(described_class).not_to be_available
    end
  end

  describe ".notify" do
    context "with options passed at initialization" do
      let(:notifier) do
        described_class.new(path: "tmp/guard_result", silent: true)
      end

      it "uses these options by default" do
        expect(File).to receive(:write).
          with("tmp/guard_result", "success\nany title\nany message\n")

        notifier.notify("any message", title: "any title")
      end

      it "overwrites object options with passed options" do
        expect(File).to receive(:write).
          with("tmp/guard_result_final", "success\nany title\nany message\n")

        notifier.notify("any message",
                        title: "any title",
                        path: "tmp/guard_result_final")
      end
    end

    it "writes to a file on success" do
      expect(File).to receive(:write).
        with("tmp/guard_result", "success\nany title\nany message\n")

      notifier.notify("any message",
                      title: "any title",
                      path: "tmp/guard_result")
    end

    it "also writes to a file on failure" do
      expect(File).to receive(:write).
        with("tmp/guard_result", "failed\nany title\nany message\n")

      notifier.notify("any message",
                      type: :failed,
                      title: "any title",
                      path: "tmp/guard_result")
    end

    # We don't have a way to return false in .available? when no path is
    # specified. So, we just don't do anything in .notify if there's no path.
    it "does not write to a file if no path is specified" do
      expect(File).to_not receive(:write)
      expect(::Guard::UI).to receive(:error).
        with ":file notifier requires a :path option"

      notifier.notify("any message")
    end
  end
end
