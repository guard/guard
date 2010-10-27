require 'spec_helper'
require 'guard/report/report_center'

describe Guard::Report::ReportCenter do
  subject { Guard::Report::ReportCenter.new }
  
  describe "ReportCenter ui registration" do
    it "accepts a new ui" do
      ui = mock("UI")
      ui.stub!(:report)
      subject.add_ui(ui)
      subject.ui.should be_include ui
    end
    it "can unload a ui" do
      ui = mock("UI")
      ui.stub!(:report)
      subject.ui.push(ui)
      subject.remove_ui(ui)
    end
    it "fail if the given ui does not have a report method" do
      ui = mock("UI")
      lambda { subject.add_ui(ui) }.should raise_error(Exception)
    end
  end
  
  describe "ReportCenter categories" do
    it "accepts a new message category" do
      cat = mock("Category")
      cat.stub!(:type).and_return(:test)
      cat.stub!(:tone).and_return(:neutral)
      subject.add_category(cat)
      subject.has_category? :test
    end
    
    it "has a default positive category" do
      cat = subject.get_category(:positive)
      cat.should_not be_nil
      cat.tone.should == :positive
      cat.type.should == :positive
      cat.name.should == "Positive"
      cat.verbosity.should == 5
    end
    
    it "has a default negative category" do
      cat = subject.get_category(:negative)
      cat.should_not be_nil
      cat.tone.should == :negative
      cat.type.should == :negative
      cat.name.should == "Negative"
      cat.verbosity.should == 5
    end
    
    it "has a default negative category" do
      cat = subject.get_category(:neutral)
      cat.should_not be_nil
      cat.tone.should == :neutral
      cat.type.should == :neutral
      cat.name.should == "Neutral"
      cat.verbosity.should == 5
    end
    
    it "fails on a category with an invalid message" do
      cat = mock("Category")
      cat.stub!(:tone).and_return :invalid
      cat.stub!(:type).and_return :success
      lambda {subject.add_category cat}.should raise_error(Exception)
    end
    
    it "fails if the same category is registered in different neutral and positive" do
      neutral = mock("Category")
      neutral.stub!(:tone).and_return :neutral
      neutral.stub!(:type).and_return :success
      
      pos = mock("Category")
      pos.stub!(:tone).and_return :positive
      pos.stub!(:type).and_return :success
      
      subject.add_category neutral
      lambda {subject.add_category pos}.should raise_error(Exception) 
    end
    
    it "does not register again a category in positive silently" do
      neutral = mock("Category")
      neutral.stub!(:tone).and_return :neutral
      neutral.stub!(:type).and_return :success
      
      neutral2 = mock("Category")
      neutral2.stub!(:tone).and_return :neutral
      neutral2.stub!(:type).and_return :success
      
      subject.add_category neutral
      subject.add_category neutral2
      
      subject.get_category(:success).should === neutral
      subject.get_category(:success).should_not === neutral2
    end
  end
  
  describe "sending message" do
    it "send a neutral message"
    it "send a positive message"
    it "send a negative message"
    it "send a message of a sub category"
    it "send a succeed message"
  end
  
  describe "UI receiving message" do
    it "receives a message"
    it "receive only success message"
    it "receive only positive message where verbosity is less than 3"
  end
end