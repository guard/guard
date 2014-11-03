require "guard/commands/notification"

RSpec.describe Guard::Commands::Notification do
  before { described_class.import }
  it "toggles the Guard notifier" do
    expect(::Guard::Notifier).to receive(:toggle)
    Pry.run_command "notification"
  end
end
