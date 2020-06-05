# frozen_string_literal: true

require "guard/commands/all"

RSpec.describe Guard::Commands::All, :stub_ui do
  include_context "with engine"
  include_context "with fake pry"

  let(:foo_group) { double }
  let(:bar_guard) { double }

  before do
    allow(Pry::Commands).to receive(:create_command).with("all") do |&block|
      FakePry.instance_eval(&block)
    end
    allow(session).to receive(:convert_scopes).with(given_scope)
                                              .and_return(converted_scope)

    described_class.import
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "runs the :run_all action" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_run_all, groups: [], plugins: []])

      FakePry.process
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "runs the :run_all action with the given scope" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_run_all, groups: [foo_group], plugins: []])

      FakePry.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "runs the :run_all action with the given scope" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_run_all, plugins: [bar_guard], groups: []])

      FakePry.process("bar")
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not run the action" do
      expect(output).to receive(:puts).with("Unknown scopes: baz")
      expect(engine).to_not receive(:async_queue_add)

      FakePry.process("baz")
    end
  end
end
