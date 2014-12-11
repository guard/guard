require "guard/internals/state"

RSpec.describe Guard::Internals::State do
  let(:options) { {} }
  subject { described_class.new(options) }

  let(:scope) { instance_double("Guard::Internals::Scope") }
  let(:plugins) { instance_double("Guard::Internals::Plugins") }
  let(:groups) { instance_double("Guard::Internals::Groups") }
  let(:session) { instance_double("Guard::Internals::Session") }

  before do
    allow(Guard::Internals::Session).to receive(:new).and_return(session)
    allow(Guard::Internals::Scope).to receive(:new).and_return(scope)
    allow(session).to receive(:debug?).and_return(false)
    allow(session).to receive(:plugins).and_return(plugins)
    allow(session).to receive(:groups).and_return(groups)
  end

  describe "#initialize" do
    describe "debugging" do
      let(:options) { { debug: debug } }
      before do
        allow(session).to receive(:debug?).and_return(debug)
        expect(Guard::Internals::Session).to receive(:new).with(debug: debug)
      end

      context "when debug is set to true" do
        let(:debug) { true }
        it "sets up debugging" do
          expect(Guard::Internals::Debugging).to receive(:start)
          subject
        end
      end

      context "when debug is set to false" do
        let(:debug) { false }
        it "does not set up debugging" do
          expect(Guard::Internals::Debugging).to_not receive(:start)
          subject
        end
      end
    end
  end

  describe "#reset_session" do
    context "with existing options" do
      let(:options) { { watchdir: "abc" } }
      let(:runner) { instance_double("Guard::Runner") }
      let(:session) { instance_double("Guard::Internals::Session") }

      before do
        allow(session).to receive(:notify_options).and_return(notify: false)
        allow(session).to receive(:options).and_return(options)
        allow(Guard::Notifier).to receive(:disconnect)
        allow(runner).to receive(:run).with(:stop)
        allow(Guard::Runner).to receive(:new).and_return(runner)
        allow(Guard::Internals::Session).to receive(:new).with(options).
          and_return(session)
        allow(Guard::Notifier).to receive(:connect)
        allow(runner).to receive(:run).with(:start)
      end

      # TODO: better tests (before/after eval)
      it "yields the block" do
        expect { |b| subject.reset_session(&b) }.to yield_control
      end

      describe "notification" do
        subject { Guard::Notifier }

        before do
          begin
            described_class.new(options).reset_session(&evaluation)
          rescue RuntimeError
          end
        end

        context "when evaluation succeeds" do
          let(:evaluation) { proc {} }
          it { is_expected.to have_received(:disconnect) }
          it { is_expected.to have_received(:connect) }
        end

        context "when evaluation fails" do
          let(:evaluation) { proc { fail "some failure" } }
          it { is_expected.to have_received(:disconnect) }
          it { is_expected.to have_received(:connect) }
        end
      end

      describe "runner" do
        subject { runner }
        before do
          begin
            described_class.new(options).reset_session(&evaluation)
          rescue RuntimeError
          end
        end

        context "when evaluation succeeds" do
          let(:evaluation) { proc {} }
          it { is_expected.to have_received(:run).with(:stop) }
          it { is_expected.to have_received(:run).with(:start) }
        end

        context "when evaluation fails" do
          let(:evaluation) { proc { fail "some failure" } }
          it { is_expected.to have_received(:run).with(:stop) }
          it { is_expected.to_not have_received(:run).with(:start) }
        end
      end
    end
  end
end
