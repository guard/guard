# frozen_string_literal: true

require "guard/config"

unless Guard::Config.new.strict?

  # Require listen now, so the requiring below doesn't use File methods
  require "listen"

  require "guard/deprecated/dsl"

  require "guard/ui"
  require "guard/config"

  RSpec.describe Guard::Deprecated::Dsl do
    subject do
      module TestModule; end.tap { |mod| described_class.add_deprecated(mod) }
    end

    describe ".evaluate_guardfile" do
      before { stub_user_guard_rb }
      before { stub_guardfile(" ") }
      before { stub_user_guardfile }
      before { stub_user_project_guardfile }
      let(:evaluator) { instance_double("Guard::Guardfile::Evaluator") }

      before do
        # TODO: this is a workaround for a bad require loop
        allow_any_instance_of(Guard::Config).to receive(:strict?)
          .and_return(false)

        require "guard/guardfile/evaluator"

        allow(Guard::Guardfile::Evaluator).to receive(:new)
          .and_return(evaluator)

        allow(evaluator).to receive(:evaluate_guardfile)

        allow(Guard::UI).to receive(:deprecation)
      end

      it "displays a deprecation warning to the user" do
        expect(Guard::UI).to receive(:deprecation)
          .with(Guard::Deprecated::Dsl::ClassMethods::EVALUATE_GUARDFILE)

        subject.evaluate_guardfile
      end

      it "delegates to Guard::Guardfile::Generator" do
        expect(Guard::Guardfile::Evaluator).to receive(:new)
          .with(foo: "bar") { evaluator }

        expect(evaluator).to receive(:evaluate_guardfile)

        subject.evaluate_guardfile(foo: "bar")
      end
    end
  end
end
