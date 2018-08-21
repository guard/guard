# frozen_string_literal: true

require "guard/commands/show"

# TODO: we only need the async queue
require "guard"

RSpec.describe Guard::Commands::Show do
  let(:output) { instance_double(Pry::Output) }

  class FakePry < Pry::Command
    def self.output; end
  end

  before do
    allow(FakePry).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("show") do |&block|
      FakePry.instance_eval(&block)
    end

    described_class.import
  end

  it "tells Guard to output DSL description" do
    expect(::Guard).to receive(:async_queue_add).with([:guard_show])
    FakePry.process
  end
end
