require 'spec_helper'
require 'guard/listeners/windows'

describe Guard::Windows do
  subject { Guard::Windows }

  if linux?
    it "isn't usable on linux" do
      subject.should_not be_usable
    end
  end

  if mac?
    it "isn't usable on Mac" do
      subject.should_not be_usable
    end
  end

  if windows?
    it "is usable on Windows 2000 and later" do
      subject.should be_usable
    end

    describe "#on_change" do
      before(:each) do
        @results = []
        @listener = Guard::Windows.new
        @listener.on_change do |files|
          @results += files
        end
      end

      it "catches a new file" do
        file = @fixture_path.join("newfile.rb")
        if File.exists?(file)
          begin
            File.delete file
          rescue
          end
        end
        File.exists?(file).should be_false
        start
        FileUtils.touch file
        stop
        begin
          File.delete file
        rescue
        end
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
        @results.should == ['spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/folder2/file2.txt']
      end
    end
  end

private

  def start
    sleep 1
    @listener.update_last_event
    Thread.new { @listener.start }
    sleep 1
  end

  def stop
    sleep 1
    @listener.stop
    sleep 1
  end

end
