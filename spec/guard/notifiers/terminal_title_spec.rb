require 'spec_helper'

describe Guard::Notifier::TerminalTitle do
  let(:notifier) { described_class.new }

  before do
    subject.stub(:puts)
  end

  describe '.available?' do
    it 'returns true' do
      described_class.should be_available
    end
  end

  describe '#notify' do
    it 'set title + first line of message to terminal title' do
      notifier.should_receive(:puts).with("\e]2;[any title] first line\a")

      notifier.notify("first line\nsecond line\nthird", :title => 'any title')
    end
  end

end
