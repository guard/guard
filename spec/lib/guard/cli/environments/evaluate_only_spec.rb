# frozen_string_literal: true

require "guard/cli/environments/evaluate_only"

RSpec.describe Guard::Cli::Environments::EvaluateOnly, :stub_ui do
  include_context "Guard options"

  subject { described_class.new(options) }

  before do
    allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
  end

  describe "#evaluate" do
    let(:evaluator) { instance_double("Guard::Guardfile::Evaluator", evaluate: true) }

    it "evaluates the guardfile" do
      expect(evaluator).to receive(:evaluate)

      subject.evaluate
    end

    it "passes options to evaluator" do
      expect(Guard::Guardfile::Evaluator).to receive(:new).with(options).and_return(evaluator)

      subject.evaluate
    end

    [
      Guard::Dsl::Error,
      Guard::Guardfile::Evaluator::NoGuardfileError,
      Guard::Guardfile::Evaluator::NoCustomGuardfile
    ].each do |error_class|
      context "when a #{error_class} error occurs" do
        before do
          allow(evaluator).to receive(:evaluate)
            .and_raise(error_class, "#{error_class} error!")
        end

        it "aborts and shows error message" do
          expect(Guard::UI).to receive(:error).with(/#{error_class} error!/)
          expect { subject.evaluate }.to raise_error(SystemExit)
        end
      end
    end
  end
end
