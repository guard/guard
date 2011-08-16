require 'spec_helper'

describe Guard::Interactor do
  subject { Guard::Interactor }

  let(:guard) { mock "guard" }

  before :each do
    Guard.stub!(:guards).and_return([guard])
    Guard.stub!(:options).and_return({})
    Guard.stub!(:listener).and_return(mock(:start => nil, :stop => nil))
    guard.should_receive(:hook).twice
  end

  describe ".run_all" do
    it "sends :run_all to all guards" do
      guard.should_receive(:run_all)
      subject.run_all
    end
  end

  describe ".stop" do
    it "sends :stop to all guards" do
      guard.should_receive(:stop)
      lambda { subject.stop }.should raise_error(SystemExit)
    end
  end

  describe ".reload" do
    it "sends :reload to all guards" do
      guard.should_receive(:reload)
      subject.reload
    end
  end
end
