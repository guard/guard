require 'guard/watcher/pattern/pathname_path'

RSpec.describe Guard::Watcher::Pattern::PathnamePath do
  subject { described_class.new(path) }
  describe '#match result' do
    subject { described_class.new(path).match(filename) }
    context 'when constructed with an unclean Pathname' do
      let(:path) { Pathname('./foo.rb') }

      context 'when matched file is a string' do
        context 'when filename matches' do
          let(:filename) { 'foo.rb' }
          specify { expect(subject).to eq([Pathname('foo.rb')]) }
        end

        context 'when filename does not match' do
          let(:filename) { 'bar.rb' }
          specify { expect(subject).to be_nil }
        end
      end

      context 'when matched file is an unclean Pathname' do
        context 'when filename matches' do
          let(:filename) { Pathname('./foo.rb') }
          specify { expect(subject).to eq([Pathname('foo.rb')]) }
        end

        context 'when filename does not match' do
          let(:filename) { Pathname('./bar.rb') }
          specify { expect(subject).to be_nil }
        end
      end
    end
  end
end
