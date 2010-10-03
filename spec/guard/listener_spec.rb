require 'spec_helper'

describe Guard::Listener do
  subject { described_class.new }
  
  its(:last_event) { should < Time.now }
  
  describe "start" do
    let(:pipe_mock) { mock("pipe", :eof? => true) }
    
    it "should use fsevent_watch on Mac OS X" do
      Sys::Uname.stub(:sysname).and_return('Darwin')
      IO.should_receive(:popen).with(/.*\/fsevent_watch\s\./).and_return(pipe_mock)
      subject.start
    end
    
    it "should use inotify_watch on Linux" do
      Sys::Uname.stub(:sysname).and_return('Linux')
      IO.should_receive(:popen).with(/.*\/inotify_watch\s\./).and_return(pipe_mock)
      subject.start
    end
    
  end
  
end