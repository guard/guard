require "guard/notifiers/emacs"

RSpec.describe Guard::Notifier::Emacs do
  let(:notifier) { described_class.new }
  let(:sheller) { Shellany::Sheller }

  describe ".available?" do
    subject { described_class }

    let(:cmd) { "emacsclient --eval '1' 2> #{IO::NULL} || echo 'N/A'" }
    let(:result) { fail "set me first" }

    before { allow(sheller).to receive(:stdout).with(cmd).and_return(result) }

    context "when the client command works" do
      let(:result) { "" }
      it { is_expected.to be_available }
    end

    context "when the client commmand does not exist" do
      let(:result) { nil }
      it { is_expected.to_not be_available }
    end

    context "when the client command produces unexpected output" do
      let(:result) { "N/A" }
      it { is_expected.to_not be_available }
    end
  end

  describe ".notify" do
    context "with options passed at initialization" do
      let(:notifier) { described_class.new(success: "Green", silent: true) }

      it "uses these options by default" do
        expect(sheller).to receive(:run) do |command, *arguments|
          expect(command).to include("emacsclient")
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"Green\" :foreground \"White\")"
          )
        end

        notifier.notify("any message")
      end

      it "overwrites object options with passed options" do
        expect(sheller).to receive(:run) do |command, *arguments|
          expect(command).to include("emacsclient")
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"LightGreen\" :foreground \"White\")"
          )
        end

        notifier.notify("any message", success: "LightGreen")
      end
    end

    context "when no color options are specified" do
      it "should set modeline color to the default color using emacsclient" do
        expect(sheller).to receive(:run) do |command, *arguments|
          expect(command).to include("emacsclient")
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"ForestGreen\" :foreground \"White\")"
          )
        end

        notifier.notify("any message")
      end
    end

    context 'when a color option is specified for "success" notifications' do
      it "should set modeline color to the specified color using emacsclient" do
        expect(sheller).to receive(:run) do |command, *arguments|
          expect(command).to include("emacsclient")
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"Orange\" :foreground \"White\")"
          )
        end

        notifier.notify("any message", success: "Orange")
      end
    end

    context 'when a color option is specified for "pending" notifications' do
      it "should set modeline color to the specified color using emacsclient" do
        expect(sheller).to receive(:run) do |command, *arguments|
          expect(command).to include("emacsclient")
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"Yellow\" :foreground \"White\")"
          )
        end

        notifier.notify("any message", type: :pending, pending: "Yellow")
      end
    end
  end
end
