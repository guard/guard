# frozen_string_literal: true

require "guard/watcher/pattern/matcher"

RSpec.describe Guard::Watcher::Pattern::Matcher do
  subject { described_class.new(obj) }
  describe "#match" do
    let(:expected) { double("match_result") }

    context "when constructed with valid matcher object" do
      let(:obj) { double("matcher") }

      context "when matched against a Pathname" do
        before do
          allow(obj).to receive(:match).and_return(expected)
        end
        let(:filename) { Pathname("foo.rb") }

        it "returns the match result" do
          expect(subject.match(filename)).to be(expected)
        end

        it "passes the Pathname to the matcher" do
          allow(obj).to receive(:match).with(filename)
          subject.match(filename)
        end
      end

      context "when matched against a String" do
        before do
          allow(obj).to receive(:match).and_return(expected)
        end
        let(:filename) { "foo.rb" }

        it "returns the match result" do
          expect(subject.match(filename)).to be(expected)
        end

        it "passes a Pathname to the matcher" do
          allow(obj).to receive(:match).with(Pathname(filename))
          subject.match(filename)
        end
      end
    end
  end

  describe "#==" do
    it "returns true for equal matchers" do
      expect(described_class.new(/spec_helper\.rb/))
        .to eq(described_class.new(/spec_helper\.rb/))
    end

    it "returns false for unequal matchers" do
      expect(described_class.new(/spec_helper\.rb/))
        .not_to eq(described_class.new(/spec_helper\.r/))
    end
  end

  describe "integration" do
    describe "#match result" do
      subject { described_class.new(obj).match(filename) }
      context "when constructed with valid regexp" do
        let(:obj) { /foo.rb$/ }

        context "when matched file is a string" do
          context "when filename matches" do
            let(:filename) { "foo.rb" }
            specify { expect(subject.to_a).to eq(["foo.rb"]) }
          end

          context "when filename does not match" do
            let(:filename) { "bar.rb" }
            specify { expect(subject).to be_nil }
          end
        end

        context "when matched file is an unclean Pathname" do
          context "when filename matches" do
            let(:filename) { Pathname("./foo.rb") }
            specify { expect(subject.to_a).to eq(["foo.rb"]) }
          end

          context "when filename does not match" do
            let(:filename) { Pathname("./bar.rb") }
            specify { expect(subject).to be_nil }
          end
        end

        context "when matched file contains a $" do
          let(:filename) { Pathname("lib$/foo.rb") }
          specify { expect(subject.to_a).to eq(["foo.rb"]) }
        end
      end
    end
  end
end
