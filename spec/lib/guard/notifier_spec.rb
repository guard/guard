# frozen_string_literal: true

require "guard/notifier"

RSpec.describe Guard::Notifier, :stub_ui do
  subject { described_class }
  let(:notifier) { instance_double("Notiffany::Notifier") }

  before do
    allow(Notiffany::Notifier).to receive(:new).and_return(notifier)
  end

  after do
    Guard::Notifier.instance_variable_set(:@notifier, nil)
  end

  describe "toggle_notification" do
    before do
      allow(notifier).to receive(:enabled?).and_return(true)
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

  describe ".notify" do
    before do
      subject.connect
      allow(notifier).to receive(:notify)
    end

    context "with no options" do
      it "notifies" do
        expect(notifier).to receive(:notify).with("A", {})
        subject.notify("A")
      end
    end

    context "with multiple parameters" do
      it "notifies" do
        expect(notifier).to receive(:notify)
          .with("A", priority: 2, image: :failed)
        subject.notify("A", priority: 2, image: :failed)
      end
    end

    context "with a runtime error" do
      before do
        allow(notifier).to receive(:notify).and_raise(RuntimeError, "an error")
      end

      it "shows an error" do
        expect(Guard::UI).to receive(:error)
          .with(/Notification failed for .+: an error/)

        subject.notify("A", priority: 2, image: :failed)
      end
    end
  end
end
