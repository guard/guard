require 'spec_helper'

describe Guard::UI do

  describe "clear" do
    context "Guard.options[:clear] is true" do
      before { ::Guard.stub(:options) { { :clear => true } } }

      it "clears the outputs if clearable" do
        Guard::UI.clearable
        Guard::UI.should_receive(:system).with('clear;')
        Guard::UI.clear
      end

      it "doesn't clear the output if already cleared" do
        Guard::UI.stub(:system)
        Guard::UI.clear
        Guard::UI.should_not_receive(:system).with('clear;')
        Guard::UI.clear
      end

      it "clears the outputs if forced" do
        Guard::UI.stub(:system)
        Guard::UI.clear
        Guard::UI.should_receive(:system).with('clear;')
        Guard::UI.clear(:force => true)
      end
    end

    context "Guard.options[:clear] is false" do
      before { ::Guard.stub(:options) { { :clear => false } } }

      it "doesn't clear the output" do
        Guard::UI.should_not_receive(:system).with('clear;')
        Guard::UI.clear
      end
    end
  end

end
