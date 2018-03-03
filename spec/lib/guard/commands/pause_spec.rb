require "guard/commands/pause"

RSpec.describe Guard::Commands::Pause do
  let(:fake_pry_class) do
    Class.new(Pry::Command) do
      def self.output; end
    end
  end

  before do
    allow(fake_pry_class).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("pause") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import
  end

  it "tells Guard to pause" do
    expect(::Guard).to receive(:async_queue_add).with([:guard_pause])
    fake_pry_class.process
  end
end
