require 'spec_helper'

describe Guard::Interactor do
  subject { Guard::Interactor.new }

  describe "#initialize" do
    it "un-lock by default" do
      subject.locked.should be_false
    end
  end

  describe "#lock" do
    it "locks" do
      subject.lock
      subject.locked.should be_true
    end
  end

  describe "#unlock" do
    it "unlocks" do
      subject.unlock
      subject.locked.should be_false
    end
  end

end
