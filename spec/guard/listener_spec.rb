require 'spec_helper'

describe Guard::Listener do
  subject { described_class }
  
  describe "init" do
    
    before(:each) { @target_os = Config::CONFIG['target_os'] }
    after(:each) { Config::CONFIG['target_os'] = @target_os }
    
    it "should use darwin listener on Mac OS X" do
      Config::CONFIG['target_os'] = 'darwin10.4.0'
      Guard::Darwin.should_receive(:new)
      subject.init
    end
    
    it "should use polling listener on Windows" do
      Config::CONFIG['target_os'] = 'win32'
      Guard::Polling.should_receive(:new)
      subject.init
    end
    
    # it "should use inotify_watch on Linux" do
    #   # Sys::Uname.stub(:sysname).and_return('Linux')
    #   IO.should_receive(:popen).with(/.*\/inotify_watch\s\./).and_return(pipe_mock)
    #   subject.start
    # end
    
  end
  
end