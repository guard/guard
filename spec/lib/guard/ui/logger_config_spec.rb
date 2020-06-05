# frozen_string_literal: true

require "guard/ui/logger_config"

RSpec.describe Guard::UI::LoggerConfig do
  describe "defaults" do
    it "flushes device by default" do
      expect(subject[:flush_seconds]).to eq(0)
    end
  end

  describe "#level=" do
    context "with a valid value" do
      before do
        subject.level = ::Logger::WARN
      end

      it "stores the level" do
        expect(subject[:level]).to eq(::Logger::WARN)
        expect(subject["level"]).to eq(::Logger::WARN)
      end
    end
  end
end
