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
    
    it "has a success category" do
      subject.has_category?(:success).should be_true
    end
    
    it "has failure category" do
      subject.has_category?(:failure).should be_true
    end
    
    it "has an info category" do
      subject.has_category?(:info).should be_true
    end
    
    it "has a debug category" do
      subject.has_category?(:debug).should be_true
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