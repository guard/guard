require 'spec_helper'

describe Guard::Listener do
  subject { Guard::Listener }

  describe ".select_and_init" do
    before(:each) { @target_os = Config::CONFIG['target_os'] }
    after(:each) { Config::CONFIG['target_os'] = @target_os }

    it "uses darwin listener on Mac OS X" do
      Config::CONFIG['target_os'] = 'darwin10.4.0'
      Guard::Darwin.stub(:usable?).and_return(true)
      Guard::Darwin.should_receive(:new)
      subject.select_and_init
    end

    it "uses windows listener on Windows" do
      Config::CONFIG['target_os'] = 'mingw'
      Guard::Windows.stub(:usable?).and_return(true)
      Guard::Windows.should_receive(:new)
      subject.select_and_init
    end

    it "uses linux listener on Linux" do
      Config::CONFIG['target_os'] = 'linux'
      Guard::Linux.stub(:usable?).and_return(true)
      Guard::Linux.should_receive(:new)
      subject.select_and_init
    end
  end

  describe "#update_last_event" do
    subject { described_class.new }

    it "updates last_event with time.now" do
      time = Time.now
      subject.update_last_event
      subject.last_event.should >= time
    end

  end

end
