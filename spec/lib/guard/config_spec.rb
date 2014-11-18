require "guard/config"

RSpec.describe Guard::Config do
  class FakeEnv < Guard::Internals::Environment
    def strict?
    end
  end

  let(:env) { instance_double(FakeEnv) }

  it { is_expected.to respond_to(:strict?) }
  it { is_expected.to respond_to(:silence_deprecations?) }

  before do
    allow(Guard::Internals::Environment).to receive(:new).with("GUARD").
      and_return(env)
    allow(env).to receive(:create_method).with(:strict?)
  end

  describe ".strict?" do
    before do
      allow(env).to receive(:strict?).and_return(result)
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
