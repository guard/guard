require "spec_helper"

describe Guard::Commands::Show do
  it "tells Guard to output DSL description" do
    expect(::Guard).to receive(:async_queue_add).with([:guard_show])
    Pry.run_command "show"
  end
end
