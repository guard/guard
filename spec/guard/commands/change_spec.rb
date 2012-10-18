require 'spec_helper'

describe 'Guard::Interactor::CHANGE' do

  let!(:guard) { ::Guard.setup }

  before do
    Guard.runner.stub(:run_on_changes)
    Pry.output.stub(:puts)
  end

  describe '#perform' do
    context 'with a file' do
      it 'runs the :run_all action with the given scope' do
        ::Guard.runner.should_receive(:run_on_changes).with(['foo'], [], [])
        Pry.run_command 'change foo'
      end
    end

    context 'with multiple files' do
      it 'runs the :run_all action with the given scope' do
        ::Guard.runner.should_receive(:run_on_changes).with(['foo', 'bar', 'baz'], [], [])
        Pry.run_command 'change foo bar baz'
      end
    end

    context 'without a file' do
      it 'does not run the :run_on_changes action' do
        ::Guard.runner.should_not_receive(:run_on_changes)
        Pry.run_command 'change'
      end
    end
  end
end
