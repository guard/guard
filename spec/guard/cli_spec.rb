require 'spec_helper'
require 'guard/cli'

describe Guard::CLI do
  let(:guard) { Guard }

  describe '#start' do
    it 'should rescue from an interrupt signal and close nicely' do
      guard.should_receive(:start).and_raise(Interrupt)
      guard.should_receive(:stop)

      subject.start
    end
  end

end
