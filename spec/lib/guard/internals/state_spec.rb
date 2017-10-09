require "guard/internals/state"

RSpec.describe Guard::Internals::State do
  let!(:engine) { Guard.init }
  let(:options) { {} }

  subject { described_class.new(engine: engine, cmdline_opts: options) }

  describe "#initialize" do
    describe "debugging" do
      let(:options) { { debug: debug } }

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
end
