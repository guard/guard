require 'spec_helper'
require 'guard/cli'

describe Guard::CLI do
  let(:guard) { Guard }

  describe '#start' do
    context 'with an interrupt signal' do
      before do
        guard.should_receive(:start).and_raise(Interrupt)
        guard.stub(:stop)
      end

      it 'exits nicely' do
        guard.should_receive(:stop)
        subject.stub(:abort)

        subject.start
      end

      it 'exits with failure status code' do
        begin
          subject.start
          raise 'Guard did not abort!'
        rescue SystemExit => e
          e.status.should_not eq(0)
        end
      end
    end
  end

end
