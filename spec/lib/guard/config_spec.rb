# frozen_string_literal: true

require "guard/config"

RSpec.describe Guard::Config do
  it { is_expected.to respond_to(:strict?) }
  it { is_expected.to respond_to(:silence_deprecations?) }

  describe ".strict?" do
    before do
      allow(subject).to receive(:strict?).and_return(result)
    end

    context "when GUARD_STRICT is set to a 'true' value" do
      let(:result) { true }
      it { is_expected.to be_strict }
    end

    context "when GUARD_STRICT is set to a 'false' value" do
      let(:result) { false }
      it { is_expected.to_not be_strict }
    end
  end
end
