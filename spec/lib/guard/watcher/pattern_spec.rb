# frozen_string_literal: true
require 'guard/watcher/pattern'

RSpec.describe Guard::Watcher::Pattern do
  describe '.create' do
    subject { described_class.create(pattern) }

    context 'when a string is given' do
      let(:pattern) { 'foo.rb' }
      it { is_expected.to be_a(described_class::SimplePath) }
    end

    context 'when a Pathname is given' do
      let(:pattern) { Pathname('foo.rb') }
      it { is_expected.to be_a(described_class::PathnamePath) }
    end

    context 'when an regexp string is given' do
      let(:pattern) { '^foo.*$' }
      it { is_expected.to be_a(described_class::Matcher) }
      it 'shows a warning' do
        expect(described_class::DeprecatedRegexp).
          to receive(:show_deprecation).with(pattern)
        subject
      end
    end

    context 'when a regexp is given' do
      let(:pattern) { /foo\.rb/ }
      it { is_expected.to be_a(described_class::Matcher) }
    end

    context 'when a custom matcher' do
      let(:pattern) { Class.new { def match; end } }
      it { is_expected.to be_a(described_class::Matcher) }
    end
  end
end
