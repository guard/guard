# frozen_string_literal: true

require "guard/terminal"

RSpec.describe Guard::Terminal do
  subject { described_class }
  it { is_expected.to respond_to(:clear) }

  let(:sheller) { class_double("Shellany::Sheller") }

  before do
    stub_const("Shellany::Sheller", sheller)
  end

  describe ".clear" do
    context "when on UNIX" do
      before { allow(Gem).to receive(:win_platform?).and_return(false) }

      context "when the clear command exists" do
        let(:result) { [0, "\e[H\e[2J", ""] }

        it "clears the screen using 'clear'" do
          expect(sheller).to receive(:system).with("printf '\33c\e[3J';")
                                             .and_return(result)
          ::Guard::Terminal.clear
        end
      end

      context "when the clear command fails" do
        let(:result) { [1, nil, 'Guard failed to run "clear;"'] }

        before do
          allow(sheller).to receive(:system).with("printf '\33c\e[3J';")
                                            .and_return(result)
        end

        it "fails" do
          expect { ::Guard::Terminal.clear }
            .to raise_error(Errno::ENOENT, /Guard failed to run "clear;"/)
        end
      end
    end

    context "when on Windows" do
      before { allow(Gem).to receive(:win_platform?).and_return(true) }

      it "clears the screen" do
        result = [0, "\f", ""]
        expect(sheller).to receive(:system).with("cls").and_return(result)
        ::Guard::Terminal.clear
      end

      context "when the clear command fails" do
        let(:result) { [1, nil, 'Guard failed to run "cls"'] }

        before do
          allow(sheller).to receive(:system).with("cls").and_return(result)
        end

        it "fails" do
          expect { ::Guard::Terminal.clear }
            .to raise_error(Errno::ENOENT, /Guard failed to run "cls"/)
        end
      end
    end
  end
end
