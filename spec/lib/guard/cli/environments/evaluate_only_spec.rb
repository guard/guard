# frozen_string_literal: true
require 'guard/cli/environments/evaluate_only'

RSpec.describe Guard::Cli::Environments::EvaluateOnly do
  subject { described_class.new(options) }
  let(:options) { double('options') }

  describe '#evaluate' do
    let(:evaluator) { instance_double('Guard::Guardfile::Evaluator') }
    let(:state) { instance_double('Guard::Internals::State') }
    let(:session) { instance_double('Guard::Internals::Session') }

    before do
      allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
      allow(evaluator).to receive(:evaluate)
      allow(Guard).to receive(:init)
      allow(Guard).to receive(:state).and_return(state)
      allow(state).to receive(:session).and_return(session)
      allow(session).to receive(:evaluator_options)
    end

    it 'calls Guard.init' do
      expect(Guard).to receive(:init)
      subject.evaluate
    end

    it 'initializes Guard with options' do
      expect(Guard).to receive(:init).with(options)
      subject.evaluate
    end

    it 'evaluates the guardfile' do
      expect(evaluator).to receive(:evaluate)
      subject.evaluate
    end

    it 'passes options to evaluator' do
      evaluator_options = double('evaluator_options')
      allow(session).to receive(:evaluator_options)
        .and_return(evaluator_options)

      expect(Guard::Guardfile::Evaluator).to receive(:new)
        .with(evaluator_options).and_return(evaluator)

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
          allow(Guard).to receive(:init)
            .and_raise(error_class, "#{error_class} error!")
        end

        it 'aborts' do
          expect { subject.evaluate }.to raise_error(SystemExit)
        end

        it 'shows error message' do
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
