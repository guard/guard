require 'spec_helper'

describe 'Guard::Interactor::SHOW' do

  describe '#perform' do
    it 'outputs the DSL description' do
      dsl_describer = ::Guard::DslDescriber.new(::Guard.options)
      allow(::Guard::DslDescriber).to receive(:new) { dsl_describer }
      expect(dsl_describer).to receive(:show)
      Pry.run_command 'show'
    end
  end

end
