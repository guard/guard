require 'spec_helper'

describe Guard::Notifier do
  subject { Guard::Notifier }

  describe ".notify" do
    before(:each) do
      @saved_guard_env = ENV["GUARD_ENV"]
      ENV["GUARD_ENV"] = 'dont_mute_notify'
    end

    #TODO someone with a mac needs to check this
    if mac?
      require 'growl'
      it "uses Growl on Mac OS X" do
        Growl.should_receive(:notify).with("great",anything())
        stub_and_execute "great", :name => "Guard"
      end
      it "uses the correct default value for icons" do
        Growl.should_receive(:notify).with("great",hash_including(:icon => subject.image_path(:success)))
        stub_and_execute "great"
      end
      it "uses the correct default value for title" do
        Growl.should_receive(:notify).with("great",hash_including(:title => "Guard"))
        stub_and_execute "great"
      end
      it "correctly sets the title" do
        Growl.should_receive(:notify).with("great", hash_including(:title => "Woot"))
        stub_and_execute "great", :title => "Woot"
      end
      it "correctly sets the image" do
        Growl.should_receive(:notify).with("great", hash_including(:icon => subject.image_path(:success)))
        stub_and_execute "great", :image => :success
      end
      it "fails to execute if #turn_off" do
        subject.turn_off
        Growl.should_receive(:notify).never
        stub_and_execute("great")
      end
      
    end

    if linux?
      describe "uses Libnotify on Linux" do
        before(:all) {
          require 'libnotify'
          subject.turn_on
        }
        it "uses libnotify on linux" do
          Libnotify.should_receive(:show).with(hash_including(:body=>"great"))
          stub_and_execute "great"
        end
        it "uses the correct default value for icons" do
          Libnotify.should_receive(:show).with(hash_including(:icon_path => subject.image_path(:success)))
          stub_and_execute "great"
        end
        it "uses the correct default value for title" do
          Libnotify.should_receive(:show).with(hash_including(:summary => "Guard"))
          stub_and_execute "great"
        end
        it "correctly sets the title" do
          Libnotify.should_receive(:show).with(hash_including(:summary => "Woot"))
          stub_and_execute "great", :title => "Woot"
        end
        it "correctly sets the image" do
          Libnotify.should_receive(:show).with(hash_including(:icon_path => subject.image_path(:success)))
          stub_and_execute "great", :image => :success
        end
        it "fails to execute if #turn_off" do
          subject.turn_off
          Libnotify.should_receive(:show).never
          stub_and_execute("great")
        end
      end
    end

    describe ".turn_off" do
      it "does nothing" do
        subject.turn_off
        subject.should_send?.should be_false
      end
    end

    describe ".turn_on" do
      it "does nothing" do
        subject.turn_on
        subject.should_send?.should be_true
      end
    end

    describe ".image_path" do
      it "should return the correct path for each symbol" do
        Pathname(subject.image_path(:success)).basename.should == Pathname("success.png")
        Pathname(subject.image_path(:pending)).basename.should == Pathname("pending.png")
        Pathname(subject.image_path(:failed)).basename.should == Pathname("failed.png")
      end
      it "should return the correct path if a path is passed to it" do
        Pathname(subject.image_path('/abc/def.png')).should == Pathname('/abc/def.png')
      end
    end
    

    after(:each) { ENV["GUARD_ENV"] = @saved_guard_env }--tag ~long_running
  end

private

  def stub_and_execute(message,input = {})
    Guard::Notifier.stub!(:libnotify_installed?).and_return true
    Guard::Notifier.stub!(:should_not_send?).and_return false

    subject.notify message, input
  end

end
