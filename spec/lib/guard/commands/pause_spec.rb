require "spec_helper"

describe Guard::Commands::Pause do
  it "tells Guard to pause" do
    expect(::Guard).to receive(:async_queue_add).with([:guard_pause])
    Pry.run_command "pause"
  end
end
