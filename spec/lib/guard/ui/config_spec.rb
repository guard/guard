require 'guard/ui/config'

RSpec.describe Guard::UI::Config do
  describe '#device' do
    context 'when not set' do
      context 'when accessed as a method' do
        it 'returns $stderr' do
          expect(subject.device).to be($stderr)
        end
      end

      context 'when accessed as a string' do
        it 'returns $stderr' do
          expect(subject['device']).to be($stderr)
        end
      end

      context 'when accessed as a symbol' do
        it 'returns $stderr' do
          expect(subject[:device]).to be($stderr)
        end
      end
    end
  end

  describe '#logger_config' do
    let(:options) { {} }
    subject { described_class.new(options) }

    let(:logger_config) { instance_double('Guard::UI::Logger::Config') }

    before do
      allow(Guard::UI::Logger::Config).to receive(:new).
        and_return(logger_config)
    end

    context 'with defaults' do
      it 'provides a logger config' do
        expect(subject.logger_config).to be(logger_config)
      end
    end

    context 'with deprecated options set' do
      context 'when set using a string' do
        subject { described_class.new('time_format': 'foo') }

        it 'passes deprecated options to logger' do
          expect(Guard::UI::Logger::Config).to receive(:new).
            with(time_format: 'foo')
          subject
        end

        it 'provides a logger config' do
          expect(subject.logger_config).to be(logger_config)
        end
      end

      context 'when set using a symbol' do
        let(:options) { { time_format: 'foo' } }

        it 'passes deprecated options to logger' do
          expect(Guard::UI::Logger::Config).to receive(:new).
            with(time_format: 'foo')
          subject
        end

        it 'provides a logger config' do
          expect(subject.logger_config).to be(logger_config)
        end
      end
    end
  end
end
