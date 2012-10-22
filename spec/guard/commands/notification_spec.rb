require 'spec_helper'

describe 'Guard::Interactor::NOTIFICATION' do

  before do
    ::Guard::Notifier.stub(:toggle)
  end

  describe '#perform' do
    it 'toggles the Guard notifier' do
      ::Guard::Notifier.should_receive(:toggle)
      Pry.run_command 'notification'
    end
  end
end
