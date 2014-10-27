require "spec_helper"

require "guard/commands/pause"

describe Guard::Commands::Pause do
  before { described_class.import }
  it "tells Guard to pause" do
    expect(::Guard).to receive(:async_queue_add).with([:guard_pause])
    Pry.run_command "pause"
  end
end
