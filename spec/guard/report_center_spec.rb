require 'spec_helper'
require 'guard/report_center'

describe Guard::ReportCenter do
  describe "Guard::ReportCenter default instance" do
    subject { Guard::ReportCenter.default }
    
    it "contains a Console instance" do
      subject.ui.first.should be_kind_of Guard::UI::Console
    end
    
    it "contains a Notifier instance" do
      subject.ui[1].should be_kind_of Guard::UI::Notifier
    end
  end
  describe "Guard::ReportCenter instance" do
    subject { Guard::ReportCenter.new }
  
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
    
      it "raise an exception when invalid options key is used" do
        ui = mock("UI")
        ui.stub!(:report)
        lambda { subject.add_ui(ui, :invalid => "Trying") }.should raise_error(Exception, "Illegal argument: options only accepts #{Guard::ReportCenter::VALID_UI_OPTIONS.inspect}, received :invalid")
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
      before :each do
        @ui = mock("UI")
        @ui.should_receive(:respond_to?).with(:report).and_return(true)
        subject.add_ui(@ui, :subscribe_to => :all)
      end
    
      it "send a success message" do
        @ui.should_receive(:report).with(:success, "Success summary", {})
        subject.report(:success, "Success summary")
      end
    
      it "send a failure message" do
        @ui.should_receive(:report).with(:failure, "Failure summary", {})
        subject.report(:failure, "Failure summary")
      end
    
      it "send a info message" do
        @ui.should_receive(:report).with(:info, "Info summary", {})
        subject.report(:info, "Info summary")
      end
    
      it "send a debug message" do
        @ui.should_receive(:report).with(:debug, "Debug summary", {})
        subject.report(:debug, "Debug summary")
      end
    
      it "raise an exception when summary is nil" do
        lambda { subject.report(:success, nil) }.should raise_error(Exception)
      end
    
      it "raise an exception when type is invalid" do
        lambda { subject.report(:invalid, "Summary") }.should raise_error(Exception)
      end
    
      it "raise an exception when invalid options key is used" do
        lambda { subject.report(:success, "Summary", :invalid => "Trying") }.should raise_error(Exception, "Invalid report: options only accepts #{Guard::ReportCenter::VALID_REPORT_OPTIONS.inspect}, received :invalid")
      end
    
      it "can contains both a summary and a detailed message" do
        @ui.should_receive(:report).with(:success, "Summary", :detail => "Detailled report.")
        subject.report(:success, "Summary", :detail => "Detailled report.")
      end
    end
  
    describe "UI receiving message" do
      before :each do
        @ui = mock("UI")
        @ui.should_receive(:respond_to?).with(:report).and_return(true)
      end
    
      after :each do
        subject.remove_ui(@ui)
        @ui = nil
      end
    
      it "receives a message" do
        subject.add_ui(@ui)
        @ui.should_receive(:report).with(:success, "Success summary", {})
        subject.report(:success, "Success summary")
      end
    
      it "receive all but debug message by default" do
        subject.add_ui(@ui)
        Guard::ReportCenter::TYPES.select { |t| t != :debug }.each do |t|
          @ui.should_receive(:report).with(t, "summary", {})
          subject.report(t, "summary")
        end
        subject.report(:debug, "summary")
        @ui.should_not_receive(:report).with(:debug, "summary", {})
      end
    
      it "receive only success message" do
        subject.add_ui(@ui, :subscribe_to => :success)
        Guard::ReportCenter::TYPES.select { |t| t != :success }.each do |t|
          @ui.should_not_receive(:report).with(t, "summary", {})
          subject.report(t, "summary")
        end
        @ui.should_receive(:report).with(:success, "summary", {})
        subject.report(:success, "summary")
      end
    
      it "receive success and failure message" do
        subject.add_ui(@ui, :subscribe_to => [:success, :failure])
        Guard::ReportCenter::TYPES.select { |t| ! [:success, :failure].include? t }.each do |t|
          @ui.should_not_receive(:report).with(t, "summary", {})
          subject.report(t, "summary")
        end
        @ui.should_receive(:report).with(:success, "summary", {})
        subject.report(:success, "summary")
        @ui.should_receive(:report).with(:failure, "summary", {})
        subject.report(:failure, "summary")
      end
    end
  end
end