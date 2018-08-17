# frozen_string_literal: true

require 'guard/watcher/pattern/simple_path'

RSpec.describe Guard::Watcher::Pattern::SimplePath do
  subject { described_class.new(path) }

  describe '#match result' do
    context 'when constructed with filename string' do
      let(:path) { 'foo.rb' }

      context 'when matched file is a string' do
        context 'when filename matches' do
          let(:filename) { 'foo.rb' }
          specify { expect(subject.match(filename)).to eq(['foo.rb']) }
        end

        context 'when filename does not match' do
          let(:filename) { 'bar.rb' }
          specify { expect(subject.match(filename)).to be_nil }
        end
      end

      context 'when matched file is an unclean Pathname' do
        context 'when filename matches' do
          let(:filename) { Pathname('./foo.rb') }
          specify { expect(subject.match(filename)).to eq(['foo.rb']) }
        end

        context 'when filename does not match' do
          let(:filename) { Pathname('./bar.rb') }
          specify { expect(subject.match(filename)).to be_nil }
        end
      end
    end
  end
end
