require "guard/notifiers/gntp"

RSpec.describe Guard::Notifier::GNTP do
  let(:notifier) { described_class.new }
  let(:gntp) { double("GNTP").as_null_object }

  before do
    allow(described_class).to receive(:require_gem_safely) { true }
    stub_const "GNTP", gntp
  end

  describe ".supported_hosts" do
    let(:supported) do
      %w(darwin linux freebsd openbsd sunos solaris mswin mingw cygwin)
    end

    it { expect(described_class.supported_hosts).to eq supported }
  end

  describe ".gem_name" do
    it { expect(described_class.gem_name).to eq "ruby_gntp" }
  end

  describe ".available?" do
    context "host is not supported" do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { "foobar" }
      end

      it "do not require ruby_gntp" do
        expect(described_class).to_not receive(:require_gem_safely)

        expect(described_class).to_not be_available
      end
    end

    context "host is supported" do
      before do
        allow(RbConfig::CONFIG).to receive(:[]).with("host_os") { "darwin" }
      end

      it "requires ruby_gntp" do
        expect(described_class).to receive(:require_gem_safely) { true }

        expect(described_class).to be_available
      end
    end
  end

  describe "#client" do
    before do
      allow(::GNTP).to receive(:new) { gntp }
      allow(gntp).to receive(:register)
    end

    it "creates a new GNTP client and memoize it" do
      expect(::GNTP).to receive(:new).
        with("Guard", "127.0.0.1", "", 23_053).once { gntp }

      notifier.send(:_client, described_class::DEFAULTS.dup)

      # 2nd call, memoized
      notifier.send(:_client, described_class::DEFAULTS.dup)
    end

    it "calls #register on the client and memoize it" do
      expect(::GNTP).to receive(:new).
        with("Guard", "127.0.0.1", "", 23_053).once { gntp }

      expect(gntp).to receive(:register).once

      notifier.send(:_client, described_class::DEFAULTS.dup)

      # 2nd call, memoized
      notifier.send(:_client, described_class::DEFAULTS.dup)
    end
  end

  describe "#notify" do
    before { allow(notifier).to receive(:_client) { gntp } }

    context "with options passed at initialization" do
      let(:notifier) { described_class.new(title: "Hello", silent: true) }

      it "uses these options by default" do
        expect(gntp).to receive(:notify).with(
          sticky: false,
          name:   "success",
          title:  "Hello",
          text:   "Welcome to Guard",
          icon:   "/tmp/welcome.png"
        )

        notifier.notify(
          "Welcome to Guard",
          type: :success,
          image: "/tmp/welcome.png"
        )
      end

      it "overwrites object options with passed options" do
        expect(gntp).to receive(:notify).with(
          sticky: false,
          name:   "success",
          title:  "Welcome",
          text:   "Welcome to Guard",
          icon:   "/tmp/welcome.png"
        )

        notifier.notify(
          "Welcome to Guard",
          type: :success,
          title: "Welcome",
          image: "/tmp/welcome.png"
        )
      end
    end

    context "without additional options" do
      it "shows the notification with the default options" do
        expect(gntp).to receive(:notify).with(
          sticky: false,
          name:   "success",
          title:  "Welcome",
          text:   "Welcome to Guard",
          icon:   "/tmp/welcome.png"
        )

        notifier.notify(
          "Welcome to Guard",
          type: :success,
          title: "Welcome",
          image: "/tmp/welcome.png"
        )
      end
    end

    context "with additional options" do
      it "can override the default options" do
        expect(gntp).to receive(:notify).with(
          sticky: true,
          name:   "pending",
          title:  "Waiting",
          text:   "Waiting for something",
          icon:   "/tmp/wait.png"
        )

        notifier.notify(
          "Waiting for something",
          type: :pending,
          title: "Waiting",
          image: "/tmp/wait.png",
          sticky: true
        )
      end
    end
  end

end
