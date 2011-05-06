require 'spec_helper'

describe Guard::Interactor do
  subject { Guard::Interactor }
  let(:guard) { mock "guard" }
  before :each do
    Guard.stub!(:guards).and_return([guard])
    Guard.stub!(:listener).and_return(mock(:start => nil, :stop => nil))
  end

  it ".run_all should send :run_all to all guards" do
    guard.should_receive(:run_all)
    subject.run_all
  end

  it ".stop should send :stop to all guards" do
    guard.should_receive(:stop)
    lambda { subject.stop }.should raise_error(SystemExit)
  end

  it ".reload should send :reload to all guards" do
    guard.should_receive(:reload)
    subject.reload
  end
end
