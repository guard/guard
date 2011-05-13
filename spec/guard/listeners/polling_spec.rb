require 'spec_helper'
require 'guard/listeners/polling'

describe Guard::Polling do

  before(:each) do
    @results = []
    @listener = Guard::Polling.new
    @listener.on_change do |files|
      @results += files
    end
  end

  describe "#on_change" do
    it "catches a new file" do
      file = @fixture_path.join("newfile.rb")
      File.exists?(file).should be_false
      start
      FileUtils.touch file
      stop
      File.delete file
      @results.should == ['spec/fixtures/newfile.rb']
    end

    it "catches a single file update" do
      file = @fixture_path.join("folder1/file1.txt")
      File.exists?(file).should be_true
      start
      FileUtils.touch file
      stop
      @results.should == ['spec/fixtures/folder1/file1.txt']
    end

    it "catches multiple file updates" do
      file1 = @fixture_path.join("folder1/file1.txt")
      file2 = @fixture_path.join("folder1/folder2/file2.txt")
      File.exists?(file1).should be_true
      File.exists?(file2).should be_true
      start
      FileUtils.touch file1
      FileUtils.touch file2
      stop
      @results.should =~ ['spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/folder2/file2.txt']
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
