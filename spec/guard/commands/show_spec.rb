require 'spec_helper'

describe 'Guard::Interactor::SHOW' do

  before do
    ::Guard::DslDescriber::stub(:show)
  end

  describe '#perform' do
    it 'shows the DSL description' do
      ::Guard::DslDescriber.should_receive(:show)
      Pry.run_command 'show'
    end
  end
end