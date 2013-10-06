require 'spec_helper'

describe Guard::Notifier::TerminalTitle do
  let(:notifier) { described_class.new }

  describe '.available?' do
    it 'returns true' do
      expect(described_class).to be_available
    end
  end

  describe '#notify' do
    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(title: 'Hello') }

      it 'uses these options by default' do
      expect(notifier).to receive(:puts).with("\e]2;[Hello] first line\a")

      notifier.notify("first line\nsecond line\nthird")
      end

      it 'overwrites object options with passed options' do
      expect(notifier).to receive(:puts).with("\e]2;[Welcome] first line\a")

      notifier.notify("first line\nsecond line\nthird", title: 'Welcome')
      end
    end

    it 'set title + first line of message to terminal title' do
      expect(notifier).to receive(:puts).with("\e]2;[any title] first line\a")

      notifier.notify("first line\nsecond line\nthird", title: 'any title')
    end
  end

  describe '.turn_off' do
    it 'clears the terminal title' do
      expect(described_class).to receive(:puts).with("\e]2;\a")

      described_class.turn_off
    end
  end

end
