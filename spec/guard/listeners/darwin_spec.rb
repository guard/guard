require 'spec_helper'
require 'guard/listeners/darwin'

describe Guard::Darwin do
  subject { Guard::Darwin }

  if windows?
    it "isn't usable on windows" do
      subject.should_not be_usable
    end
  end

  if linux?
    it "isn't usable on linux" do
      subject.should_not be_usable
    end
  end

  if mac? && Guard::Darwin.usable?
    it "is usable on 10.6" do
      subject.should be_usable
    end

    it_should_behave_like "a listener that reacts to #on_change"
    it_should_behave_like "a listener scoped to a specific directory"
  end
end
