# frozen_string_literal: true

require "guard/commands/change"

RSpec.describe Guard::Commands::Change do
  include_context 'with fake_pry_class'

  let!(:engine) { Guard.init }
  let(:output) { instance_double(Pry::Output) }

  before do
    allow(fake_pry_class).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("change") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import(engine: engine)
  end

  context "with a file" do
    it "runs the :run_on_changes action with the given file" do
      expect(engine).to receive(:async_queue_add)
        .with(modified: ["foo"], added: [], removed: [])

      fake_pry_class.process("foo")
    end
  end

  context "with multiple files" do
    it "runs the :run_on_changes action with the given files" do
      expect(engine).to receive(:async_queue_add)
        .with(modified: %w(foo bar baz), added: [], removed: [])

      fake_pry_class.process("foo", "bar", "baz")
    end
  end

  context "without a file" do
    it "does not run the :run_on_changes action" do
      expect(engine).to_not receive(:async_queue_add)
      expect(output).to receive(:puts).with("Please specify a file.")

      fake_pry_class.process
    end
  end
end
