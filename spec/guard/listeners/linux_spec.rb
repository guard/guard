require 'spec_helper'
require 'fileutils'
require 'guard/listeners/linux'

describe Guard::Linux do
  subject { Guard::Linux }

  if mac?
    it "isn't usable on 10.6" do
      subject.should_not be_usable
    end
  end

  if linux? && Guard::Linux.usable?
    it "is usable on linux" do
      subject.should be_usable
    end

    describe "#start" do
      before(:each) do
        @listener = Guard::Linux.new
      end

      it "calls watch_change on the first start" do
        @listener.should_receive(:watch_change)
        start
      end

      it "doesn't call watch_change on subsequent starts after a stop" do
        @listener.stub!(:stop)
        start
        stop
        @listener.should be_watch_change
        @listener.should_not_receive(:watch_change)
        start
        @listener.unstub!(:stop)
        stop
        @listener.should_not be_watch_change
      end

      it "should use Inotify as worker" do
        @listener.__send__(:worker).should be_a(INotify::Notifier)
      end

    end

    it_should_behave_like "a listener that reacts to #on_change" 
    it_should_behave_like "a listener scoped to a specific directory" 

    it "doesn't process a change when it is stopped" do
      @listener = described_class.new
      record_results
      file = @fixture_path.join("folder1/file1.txt")
      File.exists?(file).should be_true
      start
      @listener.inotify.should_not_receive(:process)
      stop
      File.open(file, 'w') {|f| f.write('') }
    end

  end

end
