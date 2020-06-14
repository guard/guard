# frozen_string_literal: true

require "guard/commands/scope"

RSpec.describe Guard::Commands::Scope, :stub_ui do
  include_context "with engine"
  include_context "with fake pry"

  let!(:frontend_group) { engine.groups.add("frontend") }
  let!(:dummy_plugin) { engine.plugins.add("dummy", group: frontend_group) }

  before do
    allow(Pry::Commands).to receive(:create_command).with("scope") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  context "without scope" do
    it "does not call :scope= and shows usage" do
      expect(output).to receive(:puts).with("Usage: scope <scope>")
      expect(engine.session).to_not receive(:interactor_scopes=)

      FakePry.process
    end
  end

  context "with a valid Guard group scope" do
    it "sets up the scope with the given scope" do
      expect(engine.session).to receive(:interactor_scopes=)
        .with(groups: [:frontend], plugins: [])

      FakePry.process("frontend")
    end
  end

  context "with a valid Guard plugin scope" do
    it "runs the :scope= action with the given scope" do
      expect(engine.session).to receive(:interactor_scopes=)
        .with(plugins: [:dummy], groups: [])

      FakePry.process("dummy")
    end
  end
end
