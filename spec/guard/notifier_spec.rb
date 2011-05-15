require 'spec_helper'

describe Guard::Notifier do
  subject { Guard::Notifier }

  describe ".notify" do
    before(:each) { subject.turn_on }
    after(:each)  { subject.turn_off }

    if mac?
      if growl_installed?
        it "uses Growl on Mac OS X" do
          Growl.should_receive(:notify).with("great",
            :title => "Guard",
            :icon  => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s,
            :name  => "Guard"
          )
          subject.notify 'great', :title => 'Guard'
        end
      else
        it { should_not be_enabled }
      end
    end

    if linux?
      if libnotify_installed?
        it "uses Libnotify on Linux" do
          Libnotify.should_receive(:show).with(
            :body      => "great",
            :summary   => 'Guard',
            :icon_path => Pathname.new(File.dirname(__FILE__)).join('../../images/success.png').to_s
          )
          subject.notify 'great', :title => 'Guard'
        end
      else
        it { should_not be_enabled }
      end
    end
  end

  describe ".turn_off" do
    if mac? && growl_installed?
      it "prevents the notifications" do
        Growl.should_not_receive(:notify)
        subject.notify 'great', :title => 'Guard'
      end
    elsif linux? && libnotify_installed?
      it "prevents the notifications" do
        Libnotify.should_not_receive(:show)
        subject.notify 'great', :title => 'Guard'
      end
    end

    it { should_not be_enabled }
  end

end
