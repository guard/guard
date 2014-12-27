require "guard/notifier"

RSpec.describe Guard::Notifier do
  subject { described_class }

  describe "toggle_notification" do
    let(:notifier) { instance_double("Notiffany::Notifier") }

    before do
      allow(Notiffany::Notifier).to receive(:new).and_return(notifier)
      allow(notifier).to receive(:enabled?).and_return(true)
    end

    after do
      Guard::Notifier.instance_variable_set(:@notifier, nil)
    end

    context "with available notifiers" do
      context "when currently on" do
        before do
          allow(notifier).to receive(:active?).and_return(true)
          subject.connect
        end

        it "suspends notifications" do
          expect(notifier).to receive(:turn_off)
          subject.toggle
        end
      end

      context "when currently off" do
        before do
          subject.connect
          allow(notifier).to receive(:active?).and_return(false)
        end

        it "resumes notifications" do
          expect(notifier).to receive(:turn_on)
          subject.toggle
        end
      end
    end
  end
end
