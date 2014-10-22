require "spec_helper"
require "guard/plugin"

require "guard/reevaluator.rb"

describe Guard::Reevaluator do
  let(:options) { {} }
  let(:evaluator) { instance_double(Guard::Guardfile::Evaluator) }

  subject do
    described_class.new(options)
  end

  before do
    allow(::Guard).to receive(:save_scope)
    allow(::Guard).to receive(:restore_scope)
    allow(::Guard).to receive(:evaluator).and_return(evaluator)
  end

  context "when Guardfile is modified" do
    before do
      allow(::Guard::Watcher).to receive(:match_guardfile?).
        with(["Guardfile"]).and_return(true)
    end

    it "should reevaluate guardfile" do
      expect(evaluator).to receive(:reevaluate_guardfile)
      subject.run_on_modifications(["Guardfile"])
    end
  end

  context "when Guardfile is modified" do
    before do
      allow(::Guard::Watcher).to receive(:match_guardfile?).with(["foo"]).
        and_return(false)
    end

    it "should not reevaluate guardfile" do
      expect(evaluator).to_not receive(:reevaluate_guardfile)
      subject.run_on_modifications(["foo"])
    end
  end

end
