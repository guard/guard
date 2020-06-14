# frozen_string_literal: true

require "guard/commands/notification"

RSpec.describe Guard::Commands::Notification, :stub_ui do
  include_context "with engine"
  include_context "with fake pry"

  let(:output) { instance_double(Pry::Output) }

  before do
    allow(Pry::Commands).to receive(:create_command)
      .with("notification") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  it "toggles the Guard notifier" do
    expect(::Guard::Notifier).to receive(:toggle)

    FakePry.process
  end
end
