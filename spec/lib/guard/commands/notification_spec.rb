require 'spec_helper'

describe 'Guard::Interactor::NOTIFICATION' do

  before do
    allow(::Guard::Notifier).to receive(:toggle)
  end

  describe '#perform' do
    it 'toggles the Guard notifier' do
      expect(::Guard::Notifier).to receive(:toggle)
      Pry.run_command 'notification'
    end
  end

end
