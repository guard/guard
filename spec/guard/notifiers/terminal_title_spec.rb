require 'spec_helper'

describe Guard::Notifier::TerminalTitle do
  before(:all) { Object.send(:remove_const, :TerminalTitle) if defined?(::TerminalTitle) }

  before do
    subject.stub!(:puts)

    class ::TerminalTitle
      def self.show(options) end
    end
  end

  after { Object.send(:remove_const, :TerminalTitle) if defined?(::TerminalTitle) }

  describe '.available?' do
    context 'without the silent option' do
      it 'returns true' do
        true.should be(subject.available?)
      end
    end
    context 'with the silent option' do
      it 'returns true' do
        true.should be(subject.available?)
      end
    end
  end

  describe '.notify' do
    it 'set title + first line of message to terminal title' do
      subject.should_receive(:set_terminal_title).with("[any title] first line")
      subject.notify('success', 'any title', "first line\nsecond line\nthird",
                        'any image', { })
    end
  end

  describe '.set_terminal_title' do
    it 'puts string to display terminal title' do
      subject.should_receive(:puts).with("\e]2;display this text in title\a")
      subject.set_terminal_title('display this text in title')
    end
  end
end
