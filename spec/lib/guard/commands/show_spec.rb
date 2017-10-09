# frozen_string_literal: true

require "guard/commands/show"

RSpec.describe Guard::Commands::Show, :pry do
  let!(:engine) { Guard.init }

  before do
    allow(Pry::Commands).to receive(:create_command).with("show") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import(engine: engine)
  end

  it "tells Guard to output DSL description" do
    expect(engine).to receive(:async_queue_add).with([:guard_show])

    fake_pry_class.process
  end
end
