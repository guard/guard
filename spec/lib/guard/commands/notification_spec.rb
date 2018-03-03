# frozen_string_literal: true

require "guard/commands/notification"

RSpec.describe Guard::Commands::Notification do
  let(:output) { instance_double(Pry::Output) }
  let(:fake_pry_class) do
    Class.new(Pry::Command) do
      def self.output; end
    end
  end

  before do
    allow(fake_pry_class).to receive(:output).and_return(output)
    allow(Pry::Commands).to receive(:create_command)
      .with("notification") do |&block|
      fake_pry_class.instance_eval(&block)
    end

    described_class.import
  end

  it "toggles the Guard notifier" do
    expect(::Guard::Notifier).to receive(:toggle)
    fake_pry_class.process
  end
end
