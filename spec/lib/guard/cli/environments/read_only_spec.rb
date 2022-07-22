# frozen_string_literal: true

require "guard/cli/environments/read_only"

RSpec.describe Guard::Cli::Environments::ReadOnly, :stub_ui do
  include_context "Guard options"

  before do
    allow(subject).to receive(:bundler_check)
  end

  subject { described_class.new(options) }

  describe "#evaluate" do
    let(:evaluator) { instance_double("Guard::Guardfile::Evaluator", evaluate: true) }

    def evaluate
      subject.evaluate(evaluator: evaluator)
    end

    it "checks Bundler" do
      expect(subject).to receive(:bundler_check)

      evaluate
    end

    it "evaluates the guardfile" do
      expect(evaluator).to receive(:evaluate)

      evaluate
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
          expect { evaluate }.to raise_error(SystemExit)
        end
      end
    end

    context "without a valid bundler setup" do
      before do
        allow(subject).to receive(:bundler_check).and_raise(SystemExit)
      end

      it "does not evaluate the Guardfile" do
        expect(evaluator).not_to receive(:evaluate)

        expect { evaluate }.to raise_error(SystemExit)
      end
    end
  end

  describe "#start" do
    let(:engine) { instance_double("Guard::Engine") }

    def start
      subject.start(engine: engine)
    end

    before do
      allow(engine).to receive(:start).and_return(0)
    end

    it "checks Bundler" do
      expect(subject).to receive(:bundler_check)

      start
    end

    it "start engine with options" do
      expect(engine).to receive(:start)

      start
    end

    it "returns exit code" do
      exitcode = double("exitcode")
      expect(engine).to receive(:start).and_return(exitcode)

      expect(start).to be(exitcode)
    end

    [
      Guard::Dsl::Error,
      Guard::Guardfile::Evaluator::NoGuardfileError,
      Guard::Guardfile::Evaluator::NoCustomGuardfile
    ].each do |error_class|
      context "when a #{error_class} error occurs" do
        before do
          allow(engine).to receive(:start)
            .and_raise(error_class, "#{error_class} error!")
        end

        it "aborts" do
          expect { start }.to raise_error(SystemExit)
        end

        it "shows error message" do
          expect(Guard::UI).to receive(:error).with(/#{error_class} error!/)

          expect { start }.to raise_error(SystemExit)
        end
      end
    end

    context "without a valid bundler setup" do
      before do
        allow(subject).to receive(:bundler_check).and_raise(SystemExit)
      end

      it "does not start engine" do
        expect(engine).not_to receive(:start)

        expect { start }.to raise_error(SystemExit)
      end
    end

    describe "return value" do
      let(:exitcode) { double("Fixnum") }

      before do
        allow(engine).to receive(:start).and_return(exitcode)
      end

      it "matches return value of Guard.start" do
        expect(start).to be(exitcode)
      end
    end
  end
end
