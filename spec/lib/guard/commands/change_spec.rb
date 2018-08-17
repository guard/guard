require 'guard/commands/change'

RSpec.describe Guard::Commands::Change do
  let(:output) { instance_double(Pry::Output) }

  class FakePry < Pry::Command
    def self.output
    end
  end

  before do
    allow(FakePry).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with('change') do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  context 'with a file' do
    it 'runs the :run_on_changes action with the given file' do
      expect(::Guard).to receive(:async_queue_add).
        with(modified: ['foo'], added: [], removed: [])

      FakePry.process('foo')
    end
  end

  context 'with multiple files' do
    it 'runs the :run_on_changes action with the given files' do
      expect(::Guard).to receive(:async_queue_add).
        with(modified: %w(foo bar baz), added: [], removed: [])

      FakePry.process('foo', 'bar', 'baz')
    end
  end

  context 'without a file' do
    it 'does not run the :run_on_changes action' do
      expect(::Guard).to_not receive(:async_queue_add)
      expect(output).to receive(:puts).with('Please specify a file.')

      FakePry.process
    end
  end
end
