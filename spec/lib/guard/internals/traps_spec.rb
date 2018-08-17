# frozen_string_literal: true

require 'guard/internals/traps'

RSpec.describe Guard::Internals::Traps do
  describe '.handle' do
    let(:signal_class) { class_double(Signal) }

    before do
      stub_const('Signal', signal_class)
    end

    context 'with a supported signal name' do
      let(:signal) { 'USR1' }

      it 'sets up a handler' do
        allow(Signal).to receive(:list).and_return('USR1' => 10)
        allow(Signal).to receive(:trap).with(signal) do |_, &block|
          block.call
        end

        expect { |b| described_class.handle(signal, &b) }.to yield_control
      end
    end

    context 'with an unsupported signal name' do
      let(:signal) { 'ABCD' }

      it 'does not set a handler' do
        allow(Signal).to receive(:list).and_return('KILL' => 9)
        expect(Signal).to_not receive(:trap)
        described_class.handle(signal)
      end
    end
  end
end
