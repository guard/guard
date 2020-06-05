# frozen_string_literal: true

require "guard/commands/show"

RSpec.describe Guard::Commands::Show, :stub_ui do
  include_context "with engine"
  include_context "with fake pry"

  before do
    allow(Pry::Commands).to receive(:create_command).with("show") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  it "tells Guard to output DSL description" do
    expect(engine).to receive(:async_queue_add).with([:guard_show])

    FakePry.process
  end
end
