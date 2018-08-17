# frozen_string_literal: true
require 'guard/internals/tracing'

RSpec.describe Guard::Internals::Tracing do
  let(:null) { IO::NULL }

  # NOTE: Calling system() is different from calling Kernel.system()
  #
  # We can capture system() calls by stubbing Kernel.system, but to capture
  # Kernel.system() calls, we need to stub the module's metaclass methods.
  #
  # Stubbing just Kernel.system isn't "deep" enough, but not only that,
  # we don't want to stub here, we want to TEST the stubbing
  #
  describe 'Module method tracing' do
    let(:result) { Kernel.send(meth, *args) }
    subject { result }

    let(:callback) { double('callback', call: true) }

    # Since we can't stub the C code in Ruby, only "right" way to test this is:
    # actually call a real command and compare the output
    before { allow(Kernel).to receive(meth).and_call_original }

    context 'when tracing' do
      before do
        described_class.trace(Kernel, meth) { |*args| callback.call(*args) }
        subject
      end

      after { described_class.untrace(Kernel, meth) }

      context 'with no command arguments' do
        let(:args) { ["echo >#{null}"] }

        context 'when #system' do
          let(:meth) { 'system' }

          it { is_expected.to eq(true) }

          it 'outputs command' do
            expect(callback).to have_received(:call).with("echo >#{null}")
          end
        end

        context 'when backticks' do
          let(:meth) { :` }

          it { is_expected.to eq('') }

          it 'outputs command' do
            expect(callback).to have_received(:call).with("echo >#{null}")
          end
        end
      end

      context 'with command arguments' do
        let(:args) { %w(true 123) }

        context 'when #system' do
          let(:meth) { 'system' }

          it { is_expected.to eq(true) }

          it 'outputs command arguments' do
            expect(callback).to have_received(:call).with('true', '123')
          end
        end
      end
    end

    context 'when not tracing' do
      before { subject }

      context 'with no command arguments' do
        let(:args) { ["echo test > #{null}"] }

        context 'when #system' do
          let(:meth) { :system }

          it { is_expected.to eq(true) }

          it 'does not output anything' do
            expect(callback).to_not have_received(:call)
          end
        end

        context 'when backticks' do
          let(:meth) { :` }

          it { is_expected.to eq('') }

          it 'does not output anything' do
            expect(callback).to_not have_received(:call)
          end
        end
      end

      context 'with command arguments' do
        let(:args) { %w(true 123) }

        context 'when #system' do
          let(:meth) { :system }

          it { is_expected.to eq(true) }

          it 'does not output anything' do
            expect(callback).to_not have_received(:call)
          end
        end
      end
    end
  end
end
