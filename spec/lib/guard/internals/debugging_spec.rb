# frozen_string_literal: true

require 'guard/internals/debugging'

RSpec.describe Guard::Internals::Debugging do
  let(:null) { IO::NULL }
  let(:ui) { class_double(::Guard::UI) }
  let(:tracing) { class_spy(::Guard::Internals::Tracing) }

  before do
    stub_const('::Guard::Internals::Tracing', tracing)
    stub_const('::Guard::UI', ui)
    allow(ui).to receive(:debug)
    allow(ui).to receive(:level=)
    allow(Thread).to receive(:abort_on_exception=)
  end

  after do
    described_class.send(:_reset)
  end

  describe '#start' do
    it 'traces Kernel.system' do
      expect(tracing).to receive(:trace).with(Kernel, :system) do |*_, &block|
        expect(ui).to receive(:debug).with('Command execution: foo')
        block.call 'foo'
      end
      described_class.start
    end

    it 'traces Kernel.`' do
      expect(tracing).to receive(:trace).with(Kernel, :`) do |*_, &block|
        expect(ui).to receive(:debug).with('Command execution: foo')
        block.call('foo')
      end

      described_class.start
    end

    it 'traces Open3.popen3' do
      expect(tracing).to receive(:trace).with(Open3, :popen3) do |*_, &block|
        expect(ui).to receive(:debug).with('Command execution: foo')
        block.call('foo')
      end

      described_class.start
    end

    it 'traces Kernel.spawn' do
      expect(tracing).to receive(:trace).with(Kernel, :spawn) do |*_, &block|
        expect(ui).to receive(:debug).with('Command execution: foo')
        block.call('foo')
      end

      described_class.start
    end

    context 'when not started' do
      before { described_class.start }

      it 'sets logger to debug' do
        expect(ui).to have_received(:level=).with(Logger::DEBUG)
      end

      it 'makes threads abort on exceptions' do
        expect(Thread).to have_received(:abort_on_exception=).with(true)
      end
    end

    context 'when already started' do
      before do
        allow(tracing).to receive(:trace)
        described_class.start
      end

      it 'does not set log level' do
        expect(ui).to_not receive(:level=)
        described_class.start
      end
    end
  end

  describe '#stop' do
    context 'when already started' do
      before do
        described_class.start
        described_class.stop
      end

      it 'sets logger level to info' do
        expect(ui).to have_received(:level=).with(Logger::INFO)
      end

      it 'untraces Kernel.system' do
        expect(tracing).to have_received(:untrace).with(Kernel, :system)
      end

      it 'untraces Kernel.`' do
        expect(tracing).to have_received(:untrace).with(Kernel, :`)
      end

      it 'untraces Open3.popen3' do
        expect(tracing).to have_received(:untrace).with(Kernel, :popen3)
      end
    end

    context 'when not started' do
      it 'does not set logger level' do
        described_class.stop
        expect(ui).to_not have_received(:level=)
      end
    end
  end
end
