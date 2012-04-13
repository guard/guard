require 'spec_helper'
require 'guard/interactors/simple'

describe Guard::SimpleInteractor do
  subject { Guard::SimpleInteractor.new }

  describe '#readline' do
    before do
      subject.stub(:process_input)
    end

    it 'reads all lines for processing' do
      $stdin.should_receive(:gets).and_return "First line\n"
      $stdin.should_receive(:gets).and_return "Second line\n"
      $stdin.should_receive(:gets).and_return "\x00 \tControl line\n"
      $stdin.should_receive(:gets).and_return nil

      subject.should_receive(:process_input).with('First line')
      subject.should_receive(:process_input).with('Second line')
      subject.should_receive(:process_input).with('Control line')
      subject.read_line
    end
  end

end
