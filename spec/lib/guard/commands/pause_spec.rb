# frozen_string_literal: true

require "guard/commands/pause"

RSpec.describe Guard::Commands::Pause, :stub_ui do
  include_context "with engine"
  include_context "with fake pry"

  let(:output) { instance_double(Pry::Output) }

  before do
    allow(Pry::Commands).to receive(:create_command).with("pause") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  it "tells Guard to pause" do
    expect(engine).to receive(:async_queue_add).with([:guard_pause])

    FakePry.process
  end
end
