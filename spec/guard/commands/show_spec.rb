require 'spec_helper'

describe 'Guard::Interactor::SHOW' do

  describe '#perform' do
    it 'outputs the DSL description' do
      ::Guard::DslDescriber.should_receive(:show)
      Pry.run_command 'show'
    end
  end

end
