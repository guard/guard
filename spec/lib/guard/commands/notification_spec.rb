require "guard/commands/notification"

RSpec.describe Guard::Commands::Notification, :pry do
  let!(:engine) { Guard.init }

  before do
    allow(Pry::Commands).to receive(:create_command).
      with("notification") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import(engine: engine)
  end

  it "toggles the Guard notifier" do
    expect(::Guard::Notifier).to receive(:toggle)
    fake_pry_class.process
  end
end
