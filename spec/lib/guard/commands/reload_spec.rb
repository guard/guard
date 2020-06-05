# frozen_string_literal: true

require "guard/commands/reload"

require "guard/internals/session"
require "guard/internals/state"

RSpec.describe Guard::Commands::Reload, :stub_ui do
  include_context "with engine"
  include_context "with fake pry"

  let(:foo_group) { double }
  let(:bar_guard) { double }

  before do
    allow(session).to receive(:convert_scopes).with(given_scope)
                                              .and_return(converted_scope)

    allow(Pry::Commands).to receive(:create_command).with("reload") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "triggers the :reload action" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_reload, { groups: [], plugins: [] }])

      FakePry.process
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "triggers the :reload action with the given scope" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_reload, { groups: [foo_group], plugins: [] }])

      FakePry.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "triggers the :reload action with the given scope" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_reload, { plugins: [bar_guard], groups: [] }])

      FakePry.process("bar")
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not trigger the action" do
      allow(output).to receive(:puts).with("Unknown scopes: baz")
      expect(engine).to_not receive(:async_queue_add)

      FakePry.process("baz")
    end
  end
end
