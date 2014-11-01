require "spec_helper"
require "guard/plugin"

require "guard/reevaluator.rb"
require "guard/ui"

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

    context "when Guardfile contains errors" do
      before do
        allow(evaluator).to receive(:reevaluate_guardfile) do
          fail "Could not load class Foo!"
        end
      end

      it "should not raise error to prevent being fired" do
        expect { subject.run_on_modifications(["Guardfile"]) }.
          to_not raise_error
      end

      # TODO: show backtrace?
      it "should show warning about the error" do
        expect(::Guard::UI).to receive(:warning).
          with("Failed to reevaluate file: Could not load class Foo!")

        subject.run_on_modifications(["Guardfile"])
      end

      it "should restore the scope" do
        expect(::Guard).to receive(:restore_scope)

        subject.run_on_modifications(["Guardfile"])
      end

    end
  end

  context "when Guardfile is not modified" do
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
