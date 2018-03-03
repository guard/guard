# frozen_string_literal: true

require "guard/commands/reload"

require "guard/internals/session"
require "guard/internals/state"

RSpec.describe Guard::Commands::Reload do
  let(:output) { instance_double(Pry::Output) }

  let(:state) { instance_double("Guard::Internals::State") }
  let(:session) { instance_double("Guard::Internals::Session") }

  let(:foo_group) { instance_double(Guard::Group) }
  let(:bar_guard) { instance_double(Guard::Plugin) }
  let(:fake_pry_class) do
    Class.new(Pry::Command) do
      def self.output; end
    end
  end

  before do
    allow(session).to receive(:convert_scope).with(given_scope)
                                             .and_return(converted_scope)

    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

    allow(fake_pry_class).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("reload") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "triggers the :reload action" do
      expect(Guard).to receive(:async_queue_add)
        .with([:guard_reload, { groups: [], plugins: [] }])
      fake_pry_class.process
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "triggers the :reload action with the given scope" do
      expect(Guard).to receive(:async_queue_add)
        .with([:guard_reload, { groups: [foo_group], plugins: [] }])
      fake_pry_class.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "triggers the :reload action with the given scope" do
      expect(Guard).to receive(:async_queue_add)
        .with([:guard_reload, { plugins: [bar_guard], groups: [] }])
      fake_pry_class.process("bar")
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not trigger the action" do
      allow(output).to receive(:puts).with("Unknown scopes: baz")
      expect(Guard).to_not receive(:async_queue_add)
      fake_pry_class.process("baz")
    end
  end
end
