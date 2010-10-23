require 'spec_helper'
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
      
      it "call watch_change" do
        @listener.should_receive(:watch_change)
        start
      end

      it "don't call watch_change if re start after stop" do
        start
        stop
        @listener.should_not_receive(:watch_change)
        start
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
