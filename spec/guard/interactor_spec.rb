require 'spec_helper'

describe Guard::Interactor do
  subject { Guard::Interactor.new }

  describe "#initialize" do
    it "unlocks the interactor by default" do
      subject.locked.should be_false
    end
  end

  describe "#lock" do
    it "locks the interactor" do
      subject.start
      subject.lock
      subject.locked.should be_true
    end
  end

  describe "#unlock" do
    it "unlocks the interactor" do
      subject.start
      subject.unlock
      subject.locked.should be_false
    end
  end

end
