private

  # Set the sleep time around start/stop the listener. This defaults
  # to one second but can be overridden by setting the environment
  # variable `GUARD_SLEEP`.
  #
  def sleep_time
    @sleep_time ||= ENV['GUARD_SLEEP'] ? ENV['GUARD_SLEEP'].to_f : 1
  end

  # Make the spec listen to a specific listener.
  # This automatically starts to record results for the supplied listener.
  #
  # @param [Guard::Listener] listener the Guard listener
  #
  def listen_to(listener)
    @listener = listener
    record_results
  end

  # Start the listener. Normally you use {#watch} to wrap
  # the code block that should be listen to instead of starting
  # it manually.
  #
  def start
    sleep(sleep_time)
    @listener.update_last_event
    Thread.new { @listener.start }
    sleep(sleep_time)
  end

  # Stop the listener. Normally you use {#watch} to wrap
  # the code block that should be listen to instead of stopping
  # it manually.
  #
  def stop
    sleep(sleep_time)
    @listener.stop
    sleep(sleep_time)
  end

  # Watch file changes in a code block.
  #
  # @example Watch file changes
  #   watch do
  #     File.mv file1, file2
  #   end
  #
  # @yield The block to listen for file changes
  #
  def watch
    start
    yield if block_given?
    stop
  end

  # Start recording results from the current listener.
  # You may want to use {#listen_to} to set a listener
  # instead of set it up manually.
  #
  def record_results
    # Don't fail specs due to editor swap files, etc.
    noise    = %r|\.sw.$|
    @results = []

    @listener.on_change do |files|
      @results += files.reject { |f| f =~ noise }
    end
  end

  # Get the recorded result from the listener.
  #
  # @return [Array<String>] the result files
  #
  def results
    @results.flatten
  end

  # Define a file absolute to the fixture path.
  #
  # @param [String, Array<String>] file the relative file name, separated by segment
  # @return [String] the absolute file
  #
  def fixture(*file)
    @fixture_path.join(*file)
  end

shared_examples_for 'a listener that reacts to #on_change' do
  before do
    listen_to described_class.new
  end

  context 'for a new file' do
    let(:file) { fixture('newfile.rb') }

    before { File.delete(file) if File.exists?(file) }
    after  { File.delete file }

    it 'catches the new file' do
      File.exists?(file).should be_false

      watch do
        FileUtils.touch file
      end

      results.should =~ ['spec/fixtures/newfile.rb']
    end
  end

  context 'for a single file update' do
    let(:file) { fixture('folder1', 'file1.txt') }

    it 'catches the update' do
      File.exists?(file).should be_true

      watch do
        File.open(file, 'w') { |f| f.write('') }
      end

      results.should =~ ['spec/fixtures/folder1/file1.txt']
    end
  end

  context 'for a single file chmod update' do
    let(:file) { fixture('folder1/file1.txt') }

    it 'does not catch the update' do
      File.exists?(file).should be_true

      watch do
        File.chmod(0777, file)
      end

      results.should =~ []
    end
  end

  context 'for a dotfile update' do
    let(:file) { fixture('.dotfile') }

    it "catches the update" do
      File.exists?(file).should be_true

      watch do
        File.open(file, 'w') { |f| f.write('') }
      end

      results.should =~ ['spec/fixtures/.dotfile']
    end
  end

  context 'for multiple file updates' do
    let(:file1) { fixture('folder1', 'file1.txt') }
    let(:file2) { fixture('folder1', 'folder2', 'file2.txt') }

    it 'catches the updates' do
      File.exists?(file1).should be_true
      File.exists?(file2).should be_true

      watch do
        File.open(file1, 'w') { |f| f.write('') }
        File.open(file2, 'w') { |f| f.write('') }
      end

      results.should =~ ['spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/folder2/file2.txt']
    end
  end

  context 'for a deleted file' do
    let(:file) { fixture('folder1', 'file1.txt') }

    after  { FileUtils.touch file }

    it 'does not catch the deletion' do
      File.exists?(file).should be_true

      watch do
        File.delete file
      end

      results.should =~ []
    end
  end

  context 'for a moved file' do
    let(:file1) { fixture('folder1', 'file1.txt') }
    let(:file2) { fixture('folder1', 'movedfile1.txt') }

    after { FileUtils.mv file2, file1 }

    it 'does not catch the move' do
      File.exists?(file1).should be_true
      File.exists?(file2).should be_false

      watch do
        FileUtils.mv file1, file2
      end

      results.should =~ []
    end
  end
end

shared_examples_for "a listener scoped to a specific directory" do

  let(:work_directory) { fixture('folder1') }

  let(:new_file) { work_directory.join('folder2', 'newfile.rb') }
  let(:modified) { work_directory.join('file1.txt') }

  before { listen_to described_class.new(work_directory) }
  after  { File.delete new_file }

  it 'should base paths within this directory' do
    File.exists?(modified).should be_true
    File.exists?(new_file).should be_false

    watch do
      FileUtils.touch new_file
      File.open(modified, 'w') { |f| f.write('') }
    end

    results.should =~ ['folder2/newfile.rb', 'file1.txt']
  end
end
