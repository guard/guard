require "guard/plugin"

require "guard/commands/all"

RSpec.describe Guard::Commands::All do
  before { described_class.import }

  let(:foo_group) { instance_double(Guard::Group) }
  let(:bar_guard) { instance_double(Guard::PluginUtil) }

  before do
    allow(Guard::Interactor).to receive(:convert_scope) do |*args|
      fail "Interactor#convert_scope stub called with: #{args.inspect}"
    end

    allow(Guard::Interactor).to receive(:convert_scope).with(given_scope).
      and_return(converted_scope)
  end

  context "without scope" do
    let(:given_scope) { [] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, []] }

    it "runs the :run_all action" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_run_all, groups: [], plugins: []])

      Pry.run_command "all"
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "runs the :run_all action with the given scope" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_run_all, groups: [foo_group], plugins: []])

      Pry.run_command "all foo"
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "runs the :run_all action with the given scope" do
      expect(Guard).to receive(:async_queue_add).
        with([:guard_run_all, plugins: [bar_guard], groups: []])

      Pry.run_command "all bar"
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not run the action" do
      expect(STDOUT).to receive(:print).with("Unknown scopes: baz\n")
      expect(Guard).to_not receive(:async_queue_add)
      Pry.run_command "all baz"
    end
  end
end
