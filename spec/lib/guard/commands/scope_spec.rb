require "guard/commands/scope"

require "guard/internals/session"
require "guard/internals/state"

RSpec.describe Guard::Commands::Scope do
  let(:output) { instance_double(Pry::Output) }

  let(:state) { instance_double("Guard::Internals::State") }
  let(:scope) { instance_double("Guard::Internals::Scope") }
  let(:session) { instance_double("Guard::Internals::Session") }

  let(:foo_group) { instance_double(Guard::Group) }
  let(:bar_guard) { instance_double(Guard::PluginUtil) }

  class FakePry < Pry::Command
    def self.output; end
  end

  before do
    allow(session).to receive(:convert_scope).with(given_scope).
      and_return(converted_scope)

    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

    allow(FakePry).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("scope") do |&block|
      FakePry.instance_eval(&block)
    end

    allow(state).to receive(:scope).and_return(scope)
    allow(Guard).to receive(:state).and_return(state)

    described_class.import
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "does not call :scope= and shows usage" do
      expect(output).to receive(:puts).with("Usage: scope <scope>")
      expect(scope).to_not receive(:from_interactor)
      FakePry.process
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "sets up the scope with the given scope" do
      expect(scope).to receive(:from_interactor).
        with(groups: [foo_group], plugins: [])
      FakePry.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "runs the :scope= action with the given scope" do
      expect(scope).to receive(:from_interactor).
        with(plugins: [bar_guard], groups: [])
      FakePry.process("bar")
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not change the scope and shows unknown scopes" do
      expect(output).to receive(:puts).with("Unknown scopes: baz")
      expect(scope).to_not receive(:from_interactor)
      FakePry.process("baz")
    end
  end
end
