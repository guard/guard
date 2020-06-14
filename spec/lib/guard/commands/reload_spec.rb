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
    allow(Pry::Commands).to receive(:create_command).with("reload") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  context "without scope" do
    it "triggers the :reload action" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_reload, []])

      FakePry.process
    end
  end

  context "with a valid Guard group scope" do
    it "triggers the :reload action with the given scope" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_reload, ["foo"]])

      FakePry.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    it "triggers the :reload action with the given scope" do
      expect(engine).to receive(:async_queue_add)
        .with([:guard_reload, ["bar"]])

      FakePry.process("bar")
    end
  end
end
