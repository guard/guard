require "guard/plugin"

require "guard/commands/scope"

RSpec.describe Guard::Commands::Scope do
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

    it "does not call :scope= and shows usage" do
      expect(STDOUT).to receive(:print).with("Usage: scope <scope>\n")
      expect(Guard).to_not receive(:scope=)
      Pry.run_command "scope"
    end
  end

  context "with a valid Guard group scope" do
    let(:given_scope) { ["foo"] }
    let(:converted_scope) { [{ groups: [foo_group], plugins: [] }, []] }

    it "sets up the scope with the given scope" do
      expect(Guard).to receive(:setup_scope).
        with(groups: [foo_group], plugins: [])
      Pry.run_command "scope foo"
    end
  end

  context "with a valid Guard plugin scope" do
    let(:given_scope) { ["bar"] }
    let(:converted_scope) { [{ groups: [], plugins: [bar_guard] }, []] }

    it "runs the :scope= action with the given scope" do
      expect(Guard).to receive(:setup_scope).
        with(plugins: [bar_guard], groups: [])
      Pry.run_command "scope bar"
    end
  end

  context "with an invalid scope" do
    let(:given_scope) { ["baz"] }
    let(:converted_scope) { [{ groups: [], plugins: [] }, ["baz"]] }

    it "does not change the scope and shows unknown scopes" do
      expect(STDOUT).to receive(:print).with("Unknown scopes: baz\n")
      expect(Guard).to_not receive(:scope=)
      Pry.run_command "scope baz"
    end
  end
end
