require 'spec_helper'

describe 'Guard::Interactor::PAUSE' do

  before do
    ::Guard::stub(:pause)
  end

  describe '#perform' do
    it 'pauses Guard' do
      expect(::Guard).to receive(:pause)
      Pry.run_command 'pause'
    end
  end

end