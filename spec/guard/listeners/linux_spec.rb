require 'spec_helper'
require 'fileutils'
require 'guard/listeners/linux'

describe Guard::Linux do
  subject { Guard::Linux }

  if mac?
    it "should not be usable on 10.6" do
      subject.should_not be_usable
    end
  end

  if linux?
    it "should be usable on linux" do
      subject.should be_usable
    end

    describe "start" do
      before(:each) do
        @listener = Guard::Linux.new
      end

      it "should call watch_change if first start" do
        @listener.should_receive(:watch_change)
        start
      end

      it "should not call watch_change if start after stop" do
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

    end

    describe "watch" do
      before(:each) do
        @results = []
        @listener = Guard::Linux.new
        @listener.on_change do |files|
          @results += files
        end
      end

      it "should catch new file" do
        file = @fixture_path.join("newfile.rb")
        File.exists?(file).should be_false
        start
        FileUtils.touch file
        stop
        File.delete file
        @results.should == ['spec/fixtures/newfile.rb']
      end

      it "should catch file update" do
        file = @fixture_path.join("folder1/file1.txt")
        File.exists?(file).should be_true
        start
        File.open(file, 'w') {|f| f.write('') }
        stop
        @results.should == ['spec/fixtures/folder1/file1.txt']
      end

      it "should catch files update" do
        file1 = @fixture_path.join("folder1/file1.txt")
        file2 = @fixture_path.join("folder1/folder2/file2.txt")
        File.exists?(file1).should be_true
        File.exists?(file2).should be_true
        start
        File.open(file1, 'w') {|f| f.write('') }
        File.open(file2, 'w') {|f| f.write('') }
        stop
        @results.should == ['spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/folder2/file2.txt']
      end

      it "should catch deleted file" do
        file = @fixture_path.join("folder1/file1.txt")
        File.exists?(file).should be_true
        start
        File.delete file
        stop
        FileUtils.touch file
        @results.should == ['spec/fixtures/folder1/file1.txt']
      end

      it "should catch moved file" do
        file1 = @fixture_path.join("folder1/file1.txt")
        file2 = @fixture_path.join("folder1/movedfile1.txt")
        File.exists?(file1).should be_true
        File.exists?(file2).should be_false
        start
        FileUtils.mv file1, file2
        stop
        FileUtils.mv file2, file1
        @results.should == ['spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/movedfile1.txt']
      end

      it "should not process change if stopped" do
        file = @fixture_path.join("folder1/file1.txt")
        File.exists?(file).should be_true
        start
        @listener.inotify.should_not_receive(:process)
        stop
        File.open(file, 'w') {|f| f.write('') }
      end
    end
  end

private

  def start
    sleep 1
    Thread.new { @listener.start }
    sleep 1
  end

  def stop
    sleep 1
    @listener.stop
    sleep 1
  end

end