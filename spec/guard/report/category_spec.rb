require 'spec_helper'
require 'guard/report/category'

describe Guard::Report::Category do
  subject { Guard::Report::Category.new :positive }

  it "is describe with some attributes" do
    subject.tone.should == :positive
    subject.type.should == :positive
    subject.name.should == "Positive"
    subject.verbosity.should == 5
  end
end