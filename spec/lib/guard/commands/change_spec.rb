require "spec_helper"

require "guard/commands/change"

describe Guard::Commands::Change do
  before { described_class.import }
  context "with a file" do
    it "runs the :run_on_changes action with the given file" do
      expect(::Guard).to receive(:async_queue_add).
        with(modified: ["foo"], added: [], removed: [])

      Pry.run_command "change foo"
    end
  end

  context "with multiple files" do
    it "runs the :run_on_changes action with the given files" do
      expect(::Guard).to receive(:async_queue_add).
        with(modified: ["foo", "bar", "baz"], added: [], removed: [])

      Pry.run_command "change foo bar baz"
    end
  end

  context "without a file" do
    it "does not run the :run_on_changes action" do
      expect(::Guard).to_not receive(:async_queue_add)
      expect(STDOUT).to receive(:print).with("Please specify a file.\n")
      Pry.run_command "change"
    end
  end
end
