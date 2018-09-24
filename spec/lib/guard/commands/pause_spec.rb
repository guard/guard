# frozen_string_literal: true

require "guard/commands/pause"

RSpec.describe Guard::Commands::Pause do
  class FakePry < Pry::Command
    def self.output; end
  end

  before do
    allow(FakePry).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("pause") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  it "tells Guard to pause" do
    expect(::Guard).to receive(:async_queue_add).with([:guard_pause])
    FakePry.process
  end
end
