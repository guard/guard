# frozen_string_literal: true

require "guard/cli/environments/evaluate_only"

RSpec.describe Guard::Cli::Environments::EvaluateOnly, :stub_ui do
  include_context "with engine"

  subject { described_class.new(options) }

  before do
    allow(Guard::Engine).to receive(:new).and_return(engine)
    allow(Guard::Guardfile::Evaluator).to receive(:new).with(engine).and_return(evaluator)
  end

  describe "#evaluate" do
    let(:evaluator) { instance_double("Guard::Guardfile::Evaluator") }

    before do
      allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
      allow(evaluator).to receive(:evaluate)
    end

    it "calls Guard::Engine.new" do
      expect(Guard::Engine).to receive(:new)

      subject.evaluate
    end

    it "initializes Guard::Engine.new with options" do
      expect(Guard::Engine).to receive(:new).with(options)

      subject.evaluate
    end

    it "evaluates the guardfile" do
      expect(evaluator).to receive(:evaluate)

      subject.evaluate
    end

    it "passes options to evaluator" do
      evaluator_options = double("evaluator_options")
      allow(session).to receive(:evaluator_options).and_return(evaluator_options)

      expect(Guard::Guardfile::Evaluator).to receive(:new).with(engine).and_return(evaluator)

      subject.evaluate
    end

    [
      Guard::Dsl::Error,
      Guard::Guardfile::Evaluator::NoPluginsError,
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
