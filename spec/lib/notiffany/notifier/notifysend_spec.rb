require "guard/notifiers/notifysend"

RSpec.describe Guard::Notifier::NotifySend do
  let(:notifier) { described_class.new }

  before do
    stub_const "NotifySend", double
  end

  describe ".supported_hosts" do
    let(:supported) { %w(linux freebsd openbsd sunos solaris) }
    it { expect(described_class.supported_hosts).to eq supported }
  end

  describe ".available?" do
    context "host is not supported" do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { "mswin" }
      end

      it "do not check if the binary is available" do
        expect(described_class).to_not receive(:_notifysend_binary_available?)

        expect(described_class).to_not be_available
      end
    end

    context "host is supported" do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { "linux" }
      end

      it "checks if the binary is available" do
        expect(described_class).
          to receive(:_notifysend_binary_available?) { true }

        expect(described_class).to be_available
      end
    end
  end

  describe "#notify" do
    context "with options passed at initialization" do
      let(:notifier) do
        described_class.new(image: "/tmp/hello.png", silent: true)
      end

      it "uses these options by default" do
        expect(Shellany::Sheller).to receive(:run) do |command, *arguments|
          expect(command).to eql "notify-send"
          expect(arguments).to include "-i", "/tmp/hello.png"
          expect(arguments).to include "-u", "low"
          expect(arguments).to include "-t", "3000"
          expect(arguments).to include "-h", "int:transient:1"
        end

        notifier.notify("Welcome to Guard")
      end

      it "overwrites object options with passed options" do
        expect(Shellany::Sheller).to receive(:run) do |command, *arguments|
          expect(command).to eql "notify-send"
          expect(arguments).to include "-i", "/tmp/welcome.png"
          expect(arguments).to include "-u", "low"
          expect(arguments).to include "-t", "3000"
          expect(arguments).to include "-h", "int:transient:1"
        end

        notifier.notify("Welcome to Guard", image: "/tmp/welcome.png")
      end

      it "uses the title provided in the options" do
        expect(Shellany::Sheller).to receive(:run) do |command, *arguments|
          expect(command).to eql "notify-send"
          expect(arguments).to include "Welcome to Guard"
          expect(arguments).to include "test title"
        end
        notifier.notify("Welcome to Guard", title: "test title")
      end

      it "converts notification type failed to normal urgency" do
        expect(Shellany::Sheller).to receive(:run) do |command, *arguments|
          expect(command).to eql "notify-send"
          expect(arguments).to include "-u", "normal"
        end

        notifier.notify("Welcome to Guard", type: :failed)
      end

      it "converts notification type pending to low urgency" do
        expect(Shellany::Sheller).to receive(:run) do |command, *arguments|
          expect(command).to eql "notify-send"
          expect(arguments).to include "-u", "low"
        end

        notifier.notify("Welcome to Guard", type: :pending)
      end
    end

    context "without additional options" do
      it "shows the notification with the default options" do
        expect(Shellany::Sheller).to receive(:run) do |command, *arguments|
          expect(command).to eql "notify-send"
          expect(arguments).to include "-i", "/tmp/welcome.png"
          expect(arguments).to include "-u", "low"
          expect(arguments).to include "-t", "3000"
          expect(arguments).to include "-h", "int:transient:1"
        end

        notifier.notify("Welcome to Guard", image: "/tmp/welcome.png")
      end
    end

    context "with additional options" do
      it "can override the default options" do
        expect(Shellany::Sheller).to receive(:run) do |command, *arguments|
          expect(command).to eql "notify-send"
          expect(arguments).to include "-i", "/tmp/wait.png"
          expect(arguments).to include "-u", "critical"
          expect(arguments).to include "-t", "5"
        end

        notifier.notify(
          "Waiting for something",
          type: :pending,
          image: "/tmp/wait.png",
          t: 5,
          u: :critical
        )
      end
    end

  end

end
