require 'spec_helper'

describe Guard::Notifier::TerminalTitle do

  let(:fake_terminal_title) do
    Class.new do
      def self.show(options) end
    end
  end

  before do
    subject.stub!(:puts)
    stub_const 'TerminalTitle', fake_terminal_title
  end

  describe '.available?' do
    context 'without the silent option' do
      it 'returns true' do
        subject.available?.should be_true
      end
    end

    context 'with the silent option' do
      it 'returns true' do
        subject.available?.should be_true
      end
    end
  end

  describe '.notify' do
    it 'set title + first line of message to terminal title' do
      subject.should_receive(:puts).with("\e]2;[any title] first line\a")
      subject.notify('success', 'any title', "first line\nsecond line\nthird", 'any image', { })
    end
  end
end
