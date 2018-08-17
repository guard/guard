require 'guard/commands/notification'

RSpec.describe Guard::Commands::Notification do
  let(:output) { instance_double(Pry::Output) }

  class FakePry < Pry::Command
    def self.output; end
  end

  before do
    allow(FakePry).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).
      with('notification') do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  it 'toggles the Guard notifier' do
    expect(::Guard::Notifier).to receive(:toggle)
    FakePry.process
  end
end
