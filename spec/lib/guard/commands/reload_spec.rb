require "guard/commands/reload"

require "guard/group"

RSpec.describe Guard::Commands::Reload do
  let(:output) { instance_double(Pry::Output) }

  class FakePry < Pry::Command
    def self.output; end
  end

  before do
    allow(FakePry).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("reload") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  before { described_class.import }

  let(:foo_group) { instance_double(Guard::Group) }
  let(:bar_guard) { instance_double(Guard::PluginUtil) }

  before do
    # TODO: refactor convert_scope out of Interactor
    allow(Guard::Interactor).to receive(:convert_scope) do |*args|
      fail "Interactor#convert_scope stub called with: #{args.inspect}"
    end

    allow(Guard::Interactor).to receive(:convert_scope).with(given_scope).
      and_return(converted_scope)
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "triggers the :reload action" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_reload, { groups: [], plugins: [] }])
      FakePry.process
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "triggers the :reload action with the given scope" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_reload, { groups: [foo_group], plugins: [] }])
      FakePry.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "triggers the :reload action with the given scope" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_reload, { plugins: [bar_guard], groups: [] }])
      FakePry.process("bar")
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not trigger the action" do
      allow(output).to receive(:puts).with("Unknown scopes: baz")
      expect(Guard).to_not receive(:async_queue_add)
      FakePry.process("baz")
    end
  end
end
