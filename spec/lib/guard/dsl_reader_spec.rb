# frozen_string_literal: true

require "guard/dsl_reader"

RSpec.describe Guard::DslReader do
  include_context "with engine"

  subject { described_class.new(engine) }

  describe "guard" do
    context "when it is a String" do
      let(:name) { "foo" }

      it "works without errors" do
        expect { subject.guard(name, bar: :baz) }.to_not raise_error
      end

      it "reports the name as a String" do
        subject.guard("foo", bar: :baz)

        expect(subject.plugin_names).to eq(%w[foo])
      end
    end

    context "when it is a Symbol" do
      let(:name) { :foo }

      it "works without errors" do
        expect { subject.guard(name, bar: :baz) }.to_not raise_error
      end

      it "reports the name as a String" do
        subject.guard(name, bar: :baz)
        expect(subject.plugin_names).to eq(%w[foo])
      end
    end
  end

  describe "plugin_names" do
    it "returns encountered names" do
      subject.guard("foo", bar: :baz)
      subject.guard("bar", bar: :baz)
      subject.guard("baz", bar: :baz)

      expect(subject.plugin_names).to eq(%w[foo bar baz])
    end
  end

  describe "notification" do
    it "handles arguments without errors" do
      expect { subject.notification(:off) }.to_not raise_error
    end
  end
end
