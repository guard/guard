require 'spec_helper'

describe Guard::Group do

  describe ".initialize" do
    it "accepts a name as a string and provides an accessor for it (returning a symbol)" do
      described_class.new('foo').name.should eq :foo
    end

    it "accepts a name as a symbol and provides an accessor for it (returning a symbol)" do
      described_class.new(:foo).name.should eq :foo
    end

    it "accepts options and provides an accessor for it" do
      described_class.new('foo', :halt_on_fail => true).options.should == { :halt_on_fail => true }
    end
  end

  describe '#to_s' do
    it "output Group properly" do
      group = described_class.new(:foo)
      group.to_s.should eq "foo group"
    end
  end

end
