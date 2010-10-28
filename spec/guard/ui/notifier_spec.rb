require 'spec_helper'
require 'guard/ui/notifier'

describe Guard::UI::Notifier do
  
  describe "report" do
    subject do
      notifier = Guard::UI::Notifier.new
      notifier.stub!(:notifiy)
      notifier
    end
    
    it "should notify success" do
      subject.should_receive(:notify).with("Summary", :image => :success)
      subject.report(:success, "Summary", {})
    end
    
    it "should notify failure" do
      subject.should_receive(:notify).with("Summary", :image => :failure)
      subject.report(:failure, "Summary", {})
    end
    
    it "should notify info" do
      subject.should_receive(:notify).with("Summary", :image => :info)
      subject.report(:info, "Summary", {})
    end
  end
  
  describe "notify" do
    subject { Guard::UI::Notifier.new }
    
    before(:each) { ENV["GUARD_ENV"] = 'special_test' }
    
    if mac?
      require 'growl'
      it "should use Growl on Mac OS X" do
        Growl.should_receive(:notify).with("great",
          :title => "Guard",
          :icon  => Pathname.new(File.dirname(__FILE__)).join('../../../images/success.png').to_s,
          :name  => "Guard"
        )
        subject.notify 'great', :title => 'Guard'
      end
    end
    
    if linux?
      require 'libnotify'
      it "should use Libnotify on Linux" do
        Libnotify.should_receive(:show).with(
          :body      => "great",
          :summary   => 'Guard',
          :icon_path => Pathname.new(File.dirname(__FILE__)).join('../../../images/success.png').to_s
        )
        subject.notify 'great', :title => 'Guard'
      end
    end
    
    after(:each) { ENV["GUARD_ENV"] = 'test' }
  end
  
end