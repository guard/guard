require "guard/notifiers/tmux"

RSpec.describe Guard::Notifier::Tmux do
  let(:notifier) { described_class.new }
  let(:tmux_version) { 1.7 }
  let(:sheller) { class_double("Shellany::Sheller") }

  before do
    stub_const("Shellany::Sheller", sheller)
  end

  after do
    if described_class.send(:_session)
      allow(sheller).to receive(:run).with(anything)
      described_class.send(:_end_session)
    end
  end

  describe ".available?" do
    subject { described_class }
    let(:version) { "1.7\n" }

    before do
      allow(ENV).to receive(:key?).with("TMUX").and_return(tmux_env)
      allow(sheller).to receive(:stdout).with("tmux -V").and_return(version)
    end

    context "when the TMUX environment variable is set" do
      let(:tmux_env) { true }

      context "with a recent version of tmux" do
        let(:version) { "1.8\n" }
        it { is_expected.to be_available }
      end

      context "with an outdated version of tmux" do
        let(:version) { "1.6\n" }
        it { is_expected.to_not be_available }
      end
    end

    context "when the TMUX environment variable is not set" do
      let(:tmux_env) { false }

      context "without the silent option" do
        it "shows an error message" do
          expect(::Guard::UI).to receive(:error).
            with(described_class::ERROR_NOT_INSIDE_TMUX) {}
          subject.available?
        end

        it { is_expected.to_not be_available }
      end
    end
  end

  describe "#notify" do
    context "with options passed at initialization" do
      let(:notifier) do
        described_class.new(success: "rainbow",
                            silent: true,
                            starting: "vanilla")

      end

      it "uses these options by default" do
        expect(sheller).to receive(:run).
          with("tmux set -q status-left-bg rainbow") {}

        notifier.notify("any message", type: :success)
      end

      it "overwrites object options with passed options" do
        expect(sheller).to receive(:run).
          with("tmux set -q status-left-bg black") {}

        notifier.notify("any message", type: :success, success: "black")
      end

      it "uses the initialization options for custom types by default" do
        expect(sheller).to receive(:run).
          with("tmux set -q status-left-bg vanilla") {}

        notifier.notify("any message", type: :starting)
      end
    end

    it "sets the tmux status bar color to green on success" do
      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg green") {}

      notifier.notify("any message", type: :success)
    end

    context "when success: black is passed in as an option" do
      let(:options) { { success: "black" } }

      it "on success it sets the tmux status bar color to black" do
        expect(sheller).to receive(:run).
          with("tmux set -q status-left-bg black") {}

        notifier.notify("any message", options.merge(type: :success))
      end
    end

    it "sets the tmux status bar color to red on failure" do
      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg red") {}

      notifier.notify("any message", type: :failed)
    end

    it "should set the tmux status bar color to yellow on pending" do
      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg yellow") {}

      notifier.notify("any message", type: :pending)
    end

    it "sets the tmux status bar color to green on notify" do
      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg green") {}

      notifier.notify("any message", type: :notify)
    end

    it "sets the tmux status bar color to default color on a custom type" do
      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg black") {}

      notifier.notify("any message", type: :custom, default: "black")
    end

    it "sets the tmux status bar color to default color on a custom type" do
      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg green") {}

      notifier.notify("any message", type: :custom)
    end

    it "sets the tmux status bar color to passed color on a custom type" do
      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg black") {}

      notifier.notify("any message", type: :custom, custom: "black")
    end

    context "when right status bar is passed in as an option" do
      it "should set the right tmux status bar color on success" do
        expect(sheller).to receive(:run).
          with("tmux set -q status-right-bg green") {}

        notifier.notify("any message", color_location: "status-right-bg")
      end
    end

    it "does not change colors when the change_color flag is disabled" do
      expect(sheller).to_not receive(:new)

      notifier.notify("any message", change_color: false)
    end

    it "calls display_message if the display_message flag is set" do
      expect(notifier).to receive(:display_message).
        with("notify", "Guard", "any message", display_message: true)

      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg green") {}

      notifier.notify("any message", type: :notify, display_message: true)
    end

    context "when the display_message flag is not set" do
      it "does not call display_message" do
        expect(notifier).to_not receive(:display_message)

        expect(sheller).to receive(:run).
          with("tmux set -q status-left-bg green") {}

        notifier.notify("any message")
      end
    end

    it "calls display_title if the display_title flag is set" do
      expect(notifier).to receive(:display_title).
        with("notify", "Guard", "any message", display_title: true)

      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg green") {}

      notifier.notify("any message", type: :notify, display_title: true)
    end

    it "does not call display_title if the display_title flag is not set" do
      expect(notifier).to_not receive(:display_title)
      expect(sheller).to receive(:run).
        with("tmux set -q status-left-bg green") {}

      notifier.notify("any message")
    end

    context "when color_location is passed with an array" do
      let(:options) { { color_location: %w(status-left-bg pane-border-fg) } }

      it "should set the color on multiple tmux settings" do
        expect(sheller).to receive(:run).
          with("tmux set -q status-left-bg green") {}

        expect(sheller).to receive(:run).
          with("tmux set -q pane-border-fg green") {}

        notifier.notify("any message", options)
      end
    end
  end

  describe "#display_title" do

    it "displays the title" do
      expect(sheller).to receive(:run).
        with("tmux set -q set-titles-string"\
             ' \'any title - any message\'').once {}

      notifier.display_title "success", "any title", "any message"
    end

    it "shows only the first line of the message" do
      expect(sheller).to receive(:run).
        with("tmux set -q set-titles-string"\
             ' \'any title - any message\'').once {}

      notifier.display_title "success", "any title", "any message\nline two"
    end

    context "with success message type options" do
      it "formats the message" do
        expect(sheller).to receive(:run).
          with("tmux set -q set-titles-string"\
               ' \'[any title] => any message\'').once {}

        notifier.display_title(
          "success",
          "any title",
          "any message\nline two",
          success_title_format: "[%s] => %s",
          default_title_format: "(%s) -> %s"
        )
      end
    end

    context "with pending message type options" do
      it "formats the message" do
        expect(sheller).to receive(:run).
          with("tmux set -q set-titles-string"\
               ' \'[any title] === any message\'').once {}

        notifier.display_title(
          "pending",
          "any title",
          "any message\nline two",
          pending_title_format: "[%s] === %s",
          default_title_format: "(%s) -> %s"
        )
      end
    end

    context "with failed message type options" do
      it "formats the message" do
        expect(sheller).to receive(:run).
          with("tmux set -q set-titles-string"\
               ' \'[any title] <=> any message\'').once {}

        notifier.display_title(
          "failed",
          "any title",
          "any message\nline two",
          failed_title_format: "[%s] <=> %s",
          default_title_format: "(%s) -> %s"
        )
      end
    end

  end

  describe "#display_message" do
    it "sets the display-time" do
      allow(sheller).to receive(:run).with("tmux set -q display-time 3000")
      allow(sheller).to receive(:run).with("tmux set -q message-fg white")
      allow(sheller).to receive(:run).with("tmux set -q message-bg green")
      allow(sheller).to receive(:run).
        with("tmux display"\
             ' \'any title - any message\'').once

      notifier.display_message("success",
                               "any title",
                               "any message",
                               timeout: 3)
    end

    it "displays the message" do
      allow(sheller).to receive(:run).with("tmux set -q display-time 5000")
      allow(sheller).to receive(:run).with("tmux set -q message-fg white")
      allow(sheller).to receive(:run).with("tmux set -q message-bg green")

      expect(sheller).to receive(:run).with(
        "tmux display 'any title - any message'").once {}

      notifier.display_message("success", "any title", "any message")
    end

    it "handles line-breaks" do
      expect(sheller).to receive(:run).with("tmux set -q display-time 5000") {}
      expect(sheller).to receive(:run).with("tmux set -q message-fg white") {}
      expect(sheller).to receive(:run).with("tmux set -q message-bg green") {}

      expect(sheller).to receive(:run).
        with("tmux display"\
             ' \'any title - any message xx line two\'').once {}

      notifier.display_message("success",
                               "any title",
                               "any message\nline two",
                               line_separator: " xx ")
    end

    context "with success message type options" do
      before do
        allow(sheller).to receive(:run).with("tmux set -q display-time 5000")
      end

      it "formats the message" do
        allow(sheller).to receive(:run).with("tmux set -q message-fg white")
        allow(sheller).to receive(:run).with("tmux set -q message-bg green")

        expect(sheller).to receive(:run).
          with("tmux display"\
               ' \'[any title] => any message - line two\'').once {}

        notifier.display_message("success",
                                 "any title",
                                 "any message\nline two",
                                 success_message_format: "[%s] => %s",
                                 default_message_format: "(%s) -> %s")
      end

      it "sets the foreground color based on the type for success" do
        allow(sheller).to receive(:run).with("tmux set -q message-bg green")
        allow(sheller).to receive(:run).
          with('tmux display \'any title - any message\'')

        expect(sheller).to receive(:run).with("tmux set -q message-fg green") {}

        notifier.display_message("success",
                                 "any title",
                                 "any message",
                                 success_message_color: "green")
      end

      it "sets the background color" do
        allow(sheller).to receive(:run).with("tmux set -q message-fg white")
        allow(sheller).to receive(:run).
          with('tmux display \'any title - any message\'')

        expect(sheller).to receive(:run).with("tmux set -q message-bg blue") {}

        notifier.display_message("success",
                                 "any title",
                                 "any message",
                                 success: :blue)
      end
    end

    context "with pending message type options" do
      before do
        allow(sheller).to receive(:run).with("tmux set -q display-time 5000")
      end

      it "formats the message" do
        allow(sheller).to receive(:run).with("tmux set -q message-fg white")
        allow(sheller).to receive(:run).with("tmux set -q message-bg yellow")

        expect(sheller).to receive(:run).
          with("tmux display"\
               ' \'[any title] === any message - line two\'').once {}

        notifier.display_message("pending",
                                 "any title",
                                 "any message\nline two",
                                 pending_message_format: "[%s] === %s",
                                 default_message_format: "(%s) -> %s")
      end

      it "sets the foreground color" do
        allow(sheller).to receive(:run).with("tmux set -q message-bg yellow")
        allow(sheller).to receive(:run).
          with('tmux display \'any title - any message\'').once

        expect(sheller).to receive(:run).
          with("tmux set -q message-fg blue") {}

        notifier.display_message("pending",
                                 "any title",
                                 "any message",
                                 pending_message_color: "blue")
      end

      it "sets the background color" do
        allow(sheller).to receive(:run).with("tmux set -q message-fg white")
        allow(sheller).to receive(:run).
          with('tmux display \'any title - any message\'').once

        expect(sheller).to receive(:run).with("tmux set -q message-bg white") {}

        notifier.display_message("pending",
                                 "any title",
                                 "any message",
                                 pending: :white)
      end
    end

    context "with failed message type options" do
      before do
        allow(sheller).to receive(:run).with("tmux set -q display-time 5000")
      end

      it "formats the message" do
        allow(sheller).to receive(:run).with("tmux set -q message-fg white")
        allow(sheller).to receive(:run).with("tmux set -q message-bg red")

        expect(sheller).to receive(:run).
          with("tmux display"\
               ' \'[any title] <=> any message - line two\'').once {}

        notifier.display_message("failed",
                                 "any title",
                                 "any message\nline two",
                                 failed_message_format: "[%s] <=> %s",
                                 default_message_format: "(%s) -> %s")
      end

      it "sets the foreground color" do
        allow(sheller).to receive(:run).with("tmux set -q message-bg red")
        allow(sheller).to receive(:run).with("tmux display"\
                                             ' \'any title - any message\'')

        expect(sheller).to receive(:run).with("tmux set -q message-fg red") {}

        notifier.display_message("failed",
                                 "any title",
                                 "any message",
                                 failed_message_color: "red")
      end

      it "sets the background color" do
        allow(sheller).to receive(:run).with("tmux set -q message-fg white")

        allow(sheller).to receive(:run).with("tmux display"\
                                             ' \'any title - any message\'')

        expect(sheller).to receive(:run).
          with("tmux set -q message-bg black") {}

        notifier.display_message("failed",
                                 "any title",
                                 "any message",
                                 failed: :black)
      end
    end
  end

  describe "#turn_on" do
    before do
      allow(sheller).to receive(:stdout).with("tmux show -t tty") do
        "option1 setting1\noption2 setting2\n"
      end

      allow(described_class::Client).to receive(:clients) { ["tty"] }
    end

    context "when off" do
      before do
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q -u status-left-bg")
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q -u status-right-bg")
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q -u status-left-fg")
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q -u status-right-fg")
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q -u message-bg")
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q -u message-fg")
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q -u display-time")
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q option1 setting1")
        allow(sheller).to receive(:run).
          with("tmux set -t tty -q option2 setting2")
      end
    end

    context "when on" do
      before do
        described_class.turn_on
      end

      it "does not save the current tmux options" do
        expect do
          described_class.turn_on
        end.to raise_error("Already turned on!")
      end
    end
  end

  describe "#turn_off" do
    before do
      allow(sheller).to receive(:stdout).with("tmux show -t tty") do
        "option1 setting1\noption2 setting2\n"
      end

      allow(described_class::Client).to receive(:clients) { ["tty"] }

      allow(sheller).to receive(:run).
        with("tmux set -t tty -q -u status-left-bg")
      allow(sheller).to receive(:run).
        with("tmux set -t tty -q -u status-right-bg")
      allow(sheller).to receive(:run).
        with("tmux set -t tty -q -u status-left-fg")
      allow(sheller).to receive(:run).
        with("tmux set -t tty -q -u status-right-fg")
      allow(sheller).to receive(:run).
        with("tmux set -t tty -q -u message-bg")
      allow(sheller).to receive(:run).
        with("tmux set -t tty -q -u message-fg")
      allow(sheller).to receive(:run).
        with("tmux set -t tty -q -u display-time")
      allow(sheller).to receive(:run).
        with("tmux set -t tty -q option1 setting1")
      allow(sheller).to receive(:run).
        with("tmux set -t tty -q option2 setting2")
    end

    context "when on" do
      before do
        described_class.turn_on
      end

      it "restores the tmux options" do
        expect(sheller).to receive(:run).
          with("tmux set -q -u -t tty display-time")
        expect(sheller).to receive(:run).
          with("tmux set -q -t tty option2 setting2")
        expect(sheller).to receive(:run).
          with("tmux set -q -t tty option1 setting1")
        expect(sheller).to receive(:run).
          with("tmux set -q -u -t tty status-left-bg")
        expect(sheller).to receive(:run).
          with("tmux set -q -u -t tty status-right-bg")
        expect(sheller).to receive(:run).
          with("tmux set -q -u -t tty status-right-fg")
        expect(sheller).to receive(:run).
          with("tmux set -q -u -t tty status-left-fg")
        expect(sheller).to receive(:run).
          with("tmux set -q -u -t tty message-fg")
        expect(sheller).to receive(:run).
          with("tmux set -q -u -t tty message-bg")

        described_class.turn_off
      end
    end

    context "when off" do
      before do
        allow(sheller).to receive(:run)
        described_class.turn_on
        described_class.turn_off
      end

      it "fails" do
        expect do
          described_class.turn_off
        end.to raise_error("Already turned off!")
      end
    end
  end

  describe "#clients" do
    it "removes null terminal" do
      allow(sheller).to receive(:stdout).
        with("tmux list-clients -F '\#{client_tty}'") do
        "/dev/ttys001\n/dev/ttys000\n(null)\n"
      end

      clients = Guard::Notifier::Tmux::Client.clients

      expect(clients).to include "/dev/ttys001"
      expect(clients).to include "/dev/ttys000"
      expect(clients).not_to include "(null)"
    end
  end
end
