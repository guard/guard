# frozen_string_literal: true

require "guard/internals/state"

RSpec.describe Guard::Internals::State do
  include_context "with engine"

  let(:cmdline_opts) { {} }
  subject { described_class.new(engine, cmdline_opts) }

  describe "#initialize" do
    describe "debugging" do
      let(:cmdline_opts) { { debug: debug } }

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

  describe "#session" do
    it "lazy initializes @session" do
      expect(Guard::Internals::Session).to receive(:new).with(engine.evaluator, {}).and_call_original

      subject.session
    end
  end
end
