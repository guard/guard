require "guard/commands/all"

RSpec.describe Guard::Commands::All do
  include_context 'with fake_pry_class'

  let!(:engine) { Guard.init }
  let(:foo_group) { instance_double(Guard::Group) }
  let(:bar_guard) { instance_double(Guard::Plugin) }
  let(:output) { instance_double(Pry::Output) }

  before do
    allow(engine.session).to receive(:convert_scope).with(given_scope).
      and_return(converted_scope)

    allow(fake_pry_class).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("all") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import(engine: engine)
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "runs the :run_all action" do
      expect(engine).to receive(:async_queue_add).
        with([:guard_run_all, groups: [], plugins: []])

      fake_pry_class.process
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "runs the :run_all action with the given scope" do
      expect(engine).to receive(:async_queue_add).
        with([:guard_run_all, groups: [foo_group], plugins: []])

      fake_pry_class.process("foo")
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "runs the :run_all action with the given scope" do
      expect(engine).to receive(:async_queue_add).
        with([:guard_run_all, plugins: [bar_guard], groups: []])

      fake_pry_class.process("bar")
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not run the action" do
      expect(output).to receive(:puts).with("Unknown scopes: baz")
      expect(engine).to_not receive(:async_queue_add)

      fake_pry_class.process("baz")
    end
  end
end
