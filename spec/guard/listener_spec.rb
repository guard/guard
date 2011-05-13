require 'spec_helper'

describe Guard::Listener do
  subject { Guard::Listener }

  describe ".select_and_init" do
    before(:each) { @target_os = Config::CONFIG['target_os'] }
    after(:each) { Config::CONFIG['target_os'] = @target_os }

    it "uses the Darwin listener on Mac OS X" do
      Config::CONFIG['target_os'] = 'darwin10.4.0'
      Guard::Darwin.stub(:usable?).and_return(true)
      Guard::Darwin.should_receive(:new)
      subject.select_and_init
    end

    it "uses the Windows listener on Windows" do
      Config::CONFIG['target_os'] = 'mingw'
      Guard::Windows.stub(:usable?).and_return(true)
      Guard::Windows.should_receive(:new)
      subject.select_and_init
    end

    it "uses the Linux listener on Linux" do
      Config::CONFIG['target_os'] = 'linux'
      Guard::Linux.stub(:usable?).and_return(true)
      Guard::Linux.should_receive(:new)
      subject.select_and_init
    end
  end

  describe "#update_last_event" do
    subject { described_class.new }

    it "updates the last event to the current time" do
      time = Time.now
      subject.update_last_event
      subject.last_event.to_i.should >= time.to_i
    end
  end

  describe "#modified_files" do
    subject { described_class.new }

    let(:file1) { @fixture_path.join("folder1", "file1.txt") }
    let(:file2) { @fixture_path.join("folder1", "folder2", "file2.txt") }
    let(:file3) { @fixture_path.join("folder1", "deletedfile1.txt") }

    before do
      subject.update_last_event
      sleep 0.6
    end

    context "without the :all option" do
      it "finds modified files only in the directory supplied" do
        FileUtils.touch([file1, file2, file3])
        subject.modified_files([@fixture_path.join("folder1/")], {}).should =~ ["spec/fixtures/folder1/deletedfile1.txt", "spec/fixtures/folder1/file1.txt"]
      end
    end

    context "with the :all options" do
      it "finds modified files within subdirectories" do
        FileUtils.touch([file1, file2, file3])
        subject.modified_files([@fixture_path.join("folder1/")], { :all => true }).should =~ ["spec/fixtures/folder1/deletedfile1.txt", "spec/fixtures/folder1/file1.txt", "spec/fixtures/folder1/folder2/file2.txt"]
      end
    end

    context "without updating the content" do
      it "ignores the files for the second time" do
        FileUtils.touch([file1, file2, file3])
        subject.modified_files([@fixture_path.join("folder1/")], {}).should =~ ["spec/fixtures/folder1/deletedfile1.txt", "spec/fixtures/folder1/file1.txt"]
        sleep 1
        FileUtils.touch([file1, file2, file3])
        subject.modified_files([@fixture_path.join("folder1/")], {}).should == []
        sleep 1
      end
    end

    context "with content that has changed" do
      after { File.open(file1, "w") { |f| f.write("") } }

      it "identifies the files for the second time" do
        FileUtils.touch([file1, file2, file3])
        subject.modified_files([@fixture_path.join("folder1/")], {}).should =~ ["spec/fixtures/folder1/deletedfile1.txt", "spec/fixtures/folder1/file1.txt"]
        sleep 1
        FileUtils.touch([file2, file3])
        File.open(file1, "w") { |f| f.write("changed content") }
        subject.modified_files([@fixture_path.join("folder1/")], {}).should =~ ["spec/fixtures/folder1/file1.txt"]
        sleep 1
      end
    end
  end

  describe "working directory" do

    context "unspecified" do
      subject { described_class.new }
      it "defaults to Dir.pwd" do
        subject.directory.should == Dir.pwd
      end
      it "can be not changed" do
        subject.should_not respond_to(:directory=)
      end
    end

    context "specified as first argument to ::new" do
      before :each do
        @wd = @fixture_path.join("folder1")
      end
      subject { described_class.new @wd }
      it "can be inspected" do
        subject.directory.should == @wd.to_s
      end
      it "can be not changed" do
        subject.should_not respond_to(:directory=)
      end

      it "will be used to watch" do
        subject.should_receive(:watch).with(@wd.to_s)
        @listener = subject # indeed.
        start
        stop
      end
    end

  end


end
