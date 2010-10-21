require 'spec_helper'

describe Guard::Notifier do
  subject { Guard::Notifier }
  
  describe "notify" do
    before(:each) { ENV["GUARD_ENV"] = 'special_test' }
    
    if mac?
      require 'growl'
      it "should use Growl on Mac OS X" do
        Growl.should_receive(:notify).with("great",
          :title => "Guard",
          :icon  => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
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
          :icon_path => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s
        )
        subject.notify 'great', :title => 'Guard'
      end
    end
    
    after(:each) { ENV["GUARD_ENV"] = 'test' }
  end
  
end