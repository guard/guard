# frozen_string_literal: true

require 'guard/group'

RSpec.describe Guard::Group do
  subject { described_class.new(name, options) }

  let(:name) { :foo }
  let(:options) { {} }

  describe '#name' do
    specify { expect(subject.name).to eq :foo }

    context 'when initialized from a string' do
      let(:name) { 'foo' }
      specify { expect(subject.name).to eq :foo }
    end
  end

  describe '#options' do
    context 'when provided' do
      let(:options) { { halt_on_fail: true } }
      specify { expect(subject.options).to eq options }
    end
  end

  describe '#title' do
    specify { expect(subject.title).to eq 'Foo' }
  end

  describe '#to_s' do
    specify do
      expect(subject.to_s).to eq '#<Guard::Group @name=foo @options={}>'
    end
  end
end
