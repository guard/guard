require 'spec_helper'

describe Guard::Listener do

  describe '.select_and_init' do
    before(:each) { @target_os = RbConfig::CONFIG['target_os'] }
    after(:each) { RbConfig::CONFIG['target_os'] = @target_os }

    it 'uses the Darwin listener on Mac OS X' do
      RbConfig::CONFIG['target_os'] = 'darwin10.4.0'
      Guard::Darwin.stub(:usable?).and_return(true)
      Guard::Darwin.should_receive(:new)
      described_class.select_and_init
    end

    it 'uses the Windows listener on Windows' do
      RbConfig::CONFIG['target_os'] = 'mingw'
      Guard::Windows.stub(:usable?).and_return(true)
      Guard::Windows.should_receive(:new)
      described_class.select_and_init
    end

    it 'uses the Linux listener on Linux' do
      RbConfig::CONFIG['target_os'] = 'linux'
      Guard::Linux.stub(:usable?).and_return(true)
      Guard::Linux.should_receive(:new)
      described_class.select_and_init
    end

    it 'forwards its arguments to the constructor' do
      described_class.stub!(:mac?).and_return(true)
      Guard::Darwin.stub!(:usable?).and_return(true)

      path, opts = 'path', { :foo => 23 }
      Guard::Darwin.should_receive(:new).with(path, opts).and_return(true)
      described_class.select_and_init(path, opts)
    end
  end

  describe '#all_files' do
    subject { described_class.new(@fixture_path) }

    it 'should return all files' do
      subject.all_files.should =~ Dir.glob("#{ @fixture_path }/**/*", File::FNM_DOTMATCH).select { |file| File.file?(file) }
    end
  end

  describe '#relativize_paths' do
    subject { described_class.new('/tmp') }

    let(:paths) { %w( /tmp/a /tmp/a/b /tmp/a.b/c.d ) }

    it 'should relativize paths to the configured directory' do
      subject.relativize_paths(paths).should =~ %w( a a/b a.b/c.d )
    end

    context 'when set to false' do
      subject { described_class.new('/tmp', :relativize_paths => false) }

      it 'can be disabled' do
        subject.relativize_paths(paths).should eql paths
      end
    end
  end

  describe '#update_last_event' do
    subject { described_class.new }

    it 'updates the last event to the current time' do
      time = Time.now
      subject.update_last_event
      subject.instance_variable_get(:@last_event).to_i.should >= time.to_i
    end
  end

  describe '#modified_files' do
    subject { described_class.new }

    let(:file1) { fixture('folder1', 'file1.txt') }
    let(:file2) { fixture('folder1', 'folder2', 'file2.txt') }
    let(:file3) { fixture('folder1', 'deletedfile1.txt') }
    let(:file4) { fixture('folder1', 'movedfile1.txt') }
    let(:file5) { fixture('folder1', 'folder2', 'movedfile1.txt') }

    before { listen_to subject }

    context 'without the :all option' do
      it 'finds modified files only in the directory supplied' do
        watch do
          FileUtils.touch([file1, file2, file3])
          subject.modified_files([fixture('folder1')], {}).should =~
              ['spec/fixtures/folder1/deletedfile1.txt', 'spec/fixtures/folder1/file1.txt']
        end
      end
    end

    context 'with the :all options' do
      it 'finds modified files within subdirectories' do
        watch do
          FileUtils.touch([file1, file2, file3])
          subject.modified_files([fixture('folder1')], { :all => true }).should =~
              ['spec/fixtures/folder1/deletedfile1.txt',
               'spec/fixtures/folder1/file1.txt',
               'spec/fixtures/folder1/folder2/file2.txt']
        end
      end
    end

    context 'without updating the content' do
      it 'ignores the files for the second time' do
        watch do
          FileUtils.touch([file1, file2, file3])
          subject.modified_files([fixture('folder1')], {}).should =~
              ['spec/fixtures/folder1/deletedfile1.txt', 'spec/fixtures/folder1/file1.txt']

          subject.update_last_event

          FileUtils.touch([file1, file2, file3])
          subject.modified_files([fixture('folder1')], {}).should be_empty
        end
      end
    end

    context 'with content that has changed' do
      after { File.open(file1, 'w') { |f| f.write('') } }

      it 'identifies the files for the second time' do
        watch do
          FileUtils.touch([file1, file2, file3])
          subject.modified_files([fixture('folder1')], {}).should =~
              ['spec/fixtures/folder1/deletedfile1.txt', 'spec/fixtures/folder1/file1.txt']

          subject.update_last_event

          FileUtils.touch([file2, file3])
          File.open(file1, 'w') { |f| f.write('changed content') }
          subject.modified_files([fixture('folder1')], {}).should =~
              ['spec/fixtures/folder1/file1.txt']
        end
      end
    end

    context 'without the :watch_all_modifications option' do
      after { FileUtils.touch(file3) }

      it 'defaults to false' do
        subject.instance_variable_get(:@watch_all_modifications).should eql false
      end

      it 'it should not track deleted files' do
        watch do
          FileUtils.touch([file1, file2, file3])
          subject.modified_files([fixture('folder1')], {}).should =~
              ['spec/fixtures/folder1/deletedfile1.txt', 'spec/fixtures/folder1/file1.txt']

          subject.update_last_event

          FileUtils.rm(file3)
          subject.modified_files([fixture('folder1')], {}).should =~ []
        end
      end
    end

    context 'with the :watch_all_modifications option' do
      subject { described_class.new(Dir.pwd, :watch_all_modifications => true) }

      before do
        subject.timestamp_files
        subject.update_last_event
      end

      after do
        FileUtils.touch([file1, file2, file3])
      end

      it 'should be true when set' do
        subject.instance_variable_get(:@watch_all_modifications).should eql true
      end

      it 'should track deleted files' do
        watch do
          FileUtils.touch([file1, file3])
          subject.modified_files([fixture('folder1')], { }).should =~
              ['spec/fixtures/folder1/deletedfile1.txt', 'spec/fixtures/folder1/file1.txt']

          subject.update_last_event

          FileUtils.remove_file(file3)
          subject.modified_files([fixture('folder1')], { }).should =~
              ['!spec/fixtures/folder1/deletedfile1.txt']
        end
      end

      it 'should track moved files' do
        watch do
          FileUtils.touch([file1, file3])
          subject.modified_files([@fixture_path.join('folder1')], { }).should =~
              ['spec/fixtures/folder1/deletedfile1.txt', 'spec/fixtures/folder1/file1.txt']

          subject.update_last_event

          FileUtils.move(file1, file4)
          subject.modified_files([@fixture_path.join('folder1')], { }).should =~
              ['!spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/movedfile1.txt']

          FileUtils.move(file4, file1)
        end
      end

      it 'should track deleted files with all option' do
        watch do
          FileUtils.touch([file1, file2])
          subject.modified_files([@fixture_path.join('folder1')], { :all => true }).should =~
              ['spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/folder2/file2.txt']

          subject.update_last_event

          FileUtils.remove_file(file2)
          subject.modified_files([@fixture_path.join('folder1')], { :all => true }).should =~
              ['!spec/fixtures/folder1/folder2/file2.txt']
        end
      end

      it 'should track moved files with all option' do
        watch do
          FileUtils.touch([file1, file2])
          subject.modified_files([@fixture_path.join('folder1')], { :all => true }).should =~
              ['spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/folder2/file2.txt']

          subject.update_last_event

          FileUtils.move(file1, file5)
          subject.modified_files([@fixture_path.join('folder1')], { :all => true }).should =~
              ['!spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/folder2/movedfile1.txt']

          FileUtils.move(file5, file1)
        end
      end
    end
  end

  describe 'working directory' do
    context 'unspecified' do
      subject { described_class.new }

      it 'defaults to Dir.pwd' do
        subject.instance_variable_get(:@directory).should eql Dir.pwd
      end

      it 'can be not changed' do
        subject.should_not respond_to(:directory=)
      end
    end

    context 'specified as first argument to ::new' do
      let(:working_directory) { fixture('folder1') }

      subject { described_class.new working_directory }

      before { listen_to subject }

      it 'can be inspected' do
        subject.instance_variable_get(:@directory).should eql working_directory.to_s
      end

      it 'can be not changed' do
        subject.should_not respond_to(:directory=)
      end

      it 'will be used to watch' do
        subject.should_receive(:watch).with(working_directory.to_s)
        start
        stop
      end
    end
  end

  describe '#ignore_paths' do
    it 'defaults to the default ignore paths' do
      described_class.new.ignore_paths.should == Guard::Listener::DEFAULT_IGNORE_PATHS
    end

    it 'can be added to via :ignore_paths option' do
      listener = described_class.new 'path', :ignore_paths => ['foo', 'bar']
      listener.ignore_paths.should include('foo', 'bar')
    end
  end

  describe '#exclude_ignored_paths [<dirs>]' do
    let(:ignore_paths) { nil }
    subject { described_class.new(@fixture_path, { :ignore_paths => ignore_paths }) }

    it 'returns children of <dirs>' do
      subject.exclude_ignored_paths(['spec/fixtures']).should =~
          ['spec/fixtures/.dotfile', 'spec/fixtures/folder1', 'spec/fixtures/Guardfile']
    end

    describe 'when ignore_paths set to some of <dirs> children' do
      let(:ignore_paths) { ['Guardfile', '.dotfile'] }

      it 'excludes the ignored paths' do
        subject.exclude_ignored_paths(['spec/fixtures']).should =~ ['spec/fixtures/folder1']
      end
    end
  end

end
