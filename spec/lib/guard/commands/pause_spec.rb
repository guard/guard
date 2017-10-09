# frozen_string_literal: true

require "guard/commands/pause"

RSpec.describe Guard::Commands::Pause, :pry do
  let!(:engine) { Guard.init }

  before do
    allow(Pry::Commands).to receive(:create_command).with("pause") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import(engine: engine)
  end

  it "tells Guard to pause" do
    expect(engine).to receive(:async_queue_add).with([:guard_pause])

    fake_pry_class.process
  end
end
