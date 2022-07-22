# frozen_string_literal: true

require "guard/cli/environments/write"

RSpec.describe Guard::Cli::Environments::Write, :stub_ui do
  let(:options) { {} }

  subject { described_class.new(options) }

  before do
    allow(subject).to receive(:bundler_check)
  end

  describe "#initialize_guardfile" do
    let(:evaluator) { instance_double("Guard::Guardfile::Evaluator") }
    let(:generator) { instance_double("Guard::Guardfile::Generator") }

    def initialize_guardfile(plugin_names = [])
      subject.initialize_guardfile(plugin_names, evaluator: evaluator, generator: generator)
    end

    before do
      allow(evaluator).to receive(:evaluate)
      allow(generator).to receive(:create_guardfile)
      allow(generator).to receive(:initialize_all_templates)
    end

    context "with bare option" do
      let(:options) { { bare: true } }

      it "only creates the Guardfile without initializing any Guard template" do
        allow(evaluator).to receive(:evaluate)
          .and_raise(Guard::Guardfile::Evaluator::NoGuardfileError)

        expect(generator).to receive(:create_guardfile)
        expect(generator).not_to receive(:initialize_template)
        expect(generator).not_to receive(:initialize_all_templates)

        initialize_guardfile
      end

      it "returns an exit code" do
        expect(initialize_guardfile).to be_zero
      end
    end

    it "evaluates created or existing guardfile" do
      expect(evaluator).to receive(:evaluate)
      initialize_guardfile
    end

    it "creates a Guardfile" do
      expect(evaluator).to receive(:evaluate)
        .and_raise(Guard::Guardfile::Evaluator::NoGuardfileError).once

      expect(generator).to receive(:create_guardfile)

      initialize_guardfile
    end

    it "initializes templates of all installed Guards" do
      expect(generator).to receive(:initialize_all_templates)

      initialize_guardfile
    end

    it "initializes each passed template" do
      expect(generator).to receive(:initialize_template).with("rspec")
      expect(generator).to receive(:initialize_template).with("pow")

      initialize_guardfile(%w[rspec pow])
    end

    context "when passed a guard name" do
      context "when the Guardfile is empty" do
        before do
          allow(evaluator).to receive(:evaluate)
          allow(generator).to receive(:initialize_template)
        end

        it "works without without errors" do
          expect(initialize_guardfile(%w[rspec])).to be_zero
        end

        it "adds the template" do
          expect(generator).to receive(:initialize_template).with("rspec")
          initialize_guardfile(%w[rspec])
        end
      end

      it "initializes the template of the passed Guard" do
        expect(generator).to receive(:initialize_template).with("rspec")
        initialize_guardfile(%w[rspec])
      end
    end

    it "returns an exit code" do
      expect(initialize_guardfile).to be_zero
    end

    context "when passed an unknown guard name" do
      before do
        expect(generator).to receive(:initialize_template).with("foo")
                                                          .and_raise(Guard::Guardfile::Generator::NoSuchPlugin, "foo")
      end

      it "returns an exit code" do
        expect(::Guard::UI).to receive(:error).with(
          "Could not load 'guard/foo' or '~/.guard/templates/foo'"\
          " or find class Guard::Foo\n"
        )
        expect(initialize_guardfile(%w[foo])).to be(1)
      end
    end
  end
end
