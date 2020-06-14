# frozen_string_literal: true

require "guard/ui/config"

RSpec.describe Guard::UI::Config do
  describe "#device" do
    context "when not set" do
      context "when accessed as a method" do
        it "returns $stderr" do
          expect(subject.device).to be($stderr)
        end
      end

      context "when accessed as a string" do
        it "returns $stderr" do
          expect(subject["device"]).to be($stderr)
        end
      end

      context "when accessed as a symbol" do
        it "returns $stderr" do
          expect(subject[:device]).to be($stderr)
        end
      end
    end
  end
end
