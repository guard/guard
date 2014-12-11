require "guard/plugin"

require "guard/commands/all"

require "guard/internals/session"
require "guard/internals/state"

RSpec.describe Guard::Commands::All do
  let(:foo_group) { instance_double(Guard::Group) }
  let(:bar_guard) { instance_double(Guard::Plugin) }
  let(:output) { instance_double(Pry::Output) }

  let(:state) { instance_double("Guard::Internals::State") }
  let(:session) { instance_double("Guard::Internals::Session") }

  class FakePry < Pry::Command
    def self.output
    end
  end

  before do
    allow(session).to receive(:convert_scope).with(given_scope).
      and_return(converted_scope)

    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

    allow(FakePry).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("all") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "runs the :run_all action" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_run_all, groups: [], plugins: []])

      FakePry.process
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "runs the :run_all action with the given scope" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_run_all, groups: [foo_group], plugins: []])

      FakePry.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "runs the :run_all action with the given scope" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_run_all, plugins: [bar_guard], groups: []])

      FakePry.process("bar")
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not run the action" do
      expect(output).to receive(:puts).with("Unknown scopes: baz")
      expect(Guard).to_not receive(:async_queue_add)

      FakePry.process("baz")
    end
  end
end
