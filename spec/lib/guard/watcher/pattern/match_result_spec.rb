# frozen_string_literal: true

require "guard/watcher/pattern/match_result"

RSpec.describe Guard::Watcher::Pattern::MatchResult do
  let(:match_result) { double("match_data") }
  let(:original_value) { "foo/bar.rb" }
  subject { described_class.new(match_result, original_value) }

  describe "#initialize" do
    context "with valid arguments" do
      it "does not fail" do
        expect { subject }.to_not raise_error
      end
    end
  end

  describe "#[]" do
    context "with a valid match" do
      let(:match_result) { double("match_data", to_a: %w[foo bar baz]) }

      context "when asked for the non-first item" do
        let(:index) { 1 }
        it "returns the value at given index" do
          expect(subject[index]).to eq("bar")
        end
      end

      context "when asked for the first item" do
        let(:index) { 0 }
        it "returns the full original value" do
          expect(subject[index]).to eq("foo/bar.rb")
        end
      end

      context "when asked for a name match via a symbol" do
        let(:index) { :foo }
        before do
          allow(match_result).to receive(:[]).with(:foo).and_return("baz")
        end

        it "returns the value by name" do
          expect(subject[index]).to eq("baz")
        end
      end
    end
  end
end
