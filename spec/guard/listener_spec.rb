require 'spec_helper'

describe Guard::Listener do
  subject { described_class }
  
  describe ".select_and_init" do
    before(:each) { @target_os = Config::CONFIG['target_os'] }
    after(:each) { Config::CONFIG['target_os'] = @target_os }
    
    it "should use darwin listener on Mac OS X" do
      Config::CONFIG['target_os'] = 'darwin10.4.0'
      Guard::Darwin.stub(:usable?).and_return(true)
      Guard::Darwin.should_receive(:new)
      subject.select_and_init
    end
    
    it "should use polling listener on Windows" do
      Config::CONFIG['target_os'] = 'win32'
      Guard::Polling.stub(:usable?).and_return(true)
      Guard::Polling.should_receive(:new)
      subject.select_and_init
    end
    
    it "should use linux listener on Linux" do
      Config::CONFIG['target_os'] = 'linux'
      Guard::Linux.stub(:usable?).and_return(true)
      Guard::Linux.should_receive(:new)
      subject.select_and_init
    end
  end
  
  describe "#get_and_clear_changed_files" do
    subject { Guard::Listener.new }
    
    it "should return uniq changed files and clear it" do
      subject.changed_files = ["foo", "bar", "bar"]
      subject.get_and_clear_changed_files.should == ["foo", "bar"]
      subject.changed_files.should be_empty
    end
  end
  
  
end