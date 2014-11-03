require "guard/commands/show"

RSpec.describe Guard::Commands::Show do
  before { described_class.import }
  it "tells Guard to output DSL description" do
    expect(::Guard).to receive(:async_queue_add).with([:guard_show])
    Pry.run_command "show"
  end
end
