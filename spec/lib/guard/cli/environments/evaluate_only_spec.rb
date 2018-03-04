require "guard/cli/environments/evaluate_only"

RSpec.describe Guard::Cli::Environments::EvaluateOnly do
  let!(:engine) { Guard.init }
  let(:options) { { foo: 'bar' } }
  let(:evaluator) { double(evaluate: true) }

  subject { described_class.new(options) }

  describe "#evaluate" do
    before do
      allow(Guard).to receive(:init).with(options).and_return(engine)
      allow(Guard::Guardfile::Evaluator).to receive(:new).
        with(engine: engine).and_return(evaluator)
    end

    it "calls Guard.init with options" do
      expect(Guard).to receive(:init).with(options).and_return(engine)

      subject.evaluate
    end

    it "passes engine to evaluator" do
      expect(Guard::Guardfile::Evaluator).to receive(:new).
        with(engine: engine).and_return(evaluator)

      subject.evaluate
    end

    it "evaluates the guardfile" do
      expect(evaluator).to receive(:evaluate)

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
          allow(Guard).to receive(:init).
            and_raise(error_class, "#{error_class} error!")
        end

        it "aborts" do
          expect { subject.evaluate }.to raise_error(SystemExit)
        end

        it "shows error message" do
          expect(Guard::UI).to receive(:error).with(/#{error_class} error!/)
          begin
            subject.evaluate
          rescue SystemExit
          end
        end
      end
    end
  end
end
