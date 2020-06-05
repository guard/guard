# frozen_string_literal: true

require "guard/commands/scope"

RSpec.describe Guard::Commands::Scope, :stub_ui do
  include_context "with engine"
  include_context "with fake pry"

  let(:foo_group) { double }
  let(:bar_guard) { double }

  before do
    allow(session).to receive(:convert_scopes).with(given_scope)
                                              .and_return(converted_scope)

    allow(Pry::Commands).to receive(:create_command).with("scope") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "does not call :scope= and shows usage" do
      expect(output).to receive(:puts).with("Usage: scope <scope>")
      expect(engine.session).to_not receive(:interactor_scopes=)

      FakePry.process
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "sets up the scope with the given scope" do
      expect(engine.session).to receive(:interactor_scopes=)
        .with(groups: [foo_group], plugins: [])

      FakePry.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "runs the :scope= action with the given scope" do
      expect(engine.session).to receive(:interactor_scopes=)
        .with(plugins: [bar_guard], groups: [])

      FakePry.process("bar")
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not change the scope and shows unknown scopes" do
      expect(output).to receive(:puts).with("Unknown scopes: baz")
      expect(engine.session).to_not receive(:interactor_scopes=)

      FakePry.process("baz")
    end
  end
end
