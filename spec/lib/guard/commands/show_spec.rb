require "guard/commands/show"

# TODO: we only need the async queue
require "guard"

RSpec.describe Guard::Commands::Show do
  let(:output) { instance_double(Pry::Output) }
  let(:fake_pry_class) do
    Class.new(Pry::Command) do
      def self.output; end
    end
  end

  before do
    allow(fake_pry_class).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command).with("show") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import
  end

  it "tells Guard to output DSL description" do
    expect(::Guard).to receive(:async_queue_add).with([:guard_show])
    fake_pry_class.process
  end
end
