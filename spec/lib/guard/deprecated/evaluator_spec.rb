require "guard/config"

unless Guard::Config.new.strict?

  require "guard/deprecated/evaluator"
  require "guard/reevaluator"

  RSpec.describe Guard::Deprecated::Evaluator do
    subject do
      class TestClass
        def evaluate
        end
      end
      described_class.add_deprecated(TestClass)
      TestClass.new
    end

    before do
      allow(Guard::UI).to receive(:deprecation)
    end

    describe "#evaluate_guardfile" do
      before do
        allow(subject).to receive(:evaluate)
      end

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Evaluator::EVALUATE_GUARDFILE)
        subject.evaluate_guardfile
      end

      it "calls the recommended method" do
        expect(subject).to receive(:evaluate)
        subject.evaluate_guardfile
      end
    end

    describe "#reevaluate_guardfile" do
      let(:reevaluator) { instance_double("Guard::Reevaluator") }
      before do
        allow(Guard::Reevaluator).to receive(:new).and_return(reevaluator)
        allow(reevaluator).to receive(:reevaluate)
      end

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation).
          with(Guard::Deprecated::Evaluator::REEVALUATE_GUARDFILE)
        subject.reevaluate_guardfile
      end

      it "calls the recommended method" do
        expect(reevaluator).to receive(:reevaluate)
        subject.reevaluate_guardfile
      end
    end
  end
end
