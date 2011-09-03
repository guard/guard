private

  def start
    sleep(@rest_delay || 1)
    @listener.update_last_event
    Thread.new { @listener.start }
    sleep(@rest_delay || 1)
  end

  def record_results
    noise = %r|\.sw.$|  # don't fail specs due to editor swap files, etc.

    @results = []
    @listener.on_change do |files|
      @results += files.reject { |f| f =~ noise }
    end
  end

  def stop
    sleep(@rest_delay || 1)
    @listener.stop
    sleep(@rest_delay || 1)
  end

  def results
    @results.flatten
  end

shared_examples_for 'a listener that reacts to #on_change' do |rest_delay|
  before(:each) do
    @rest_delay = rest_delay if rest_delay.is_a?(Integer) || rest_delay.is_a?(Float) # jruby workaround
    @listener = described_class.new
    record_results
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
    results.should =~ ['spec/fixtures/newfile.rb']
  end

  it "catches a single file update" do
    file = @fixture_path.join("folder1/file1.txt")
    File.exists?(file).should be_true
    start
    File.open(file, 'w') { |f| f.write('') }
    stop
    results.should =~ ['spec/fixtures/folder1/file1.txt']
  end

  it "not catches a single file chmod update" do
    file = @fixture_path.join("folder1/file1.txt")
    File.exists?(file).should be_true
    start
    File.chmod(0777, file)
    stop
    results.should =~ []
  end

  it "catches a dotfile update" do
    file = @fixture_path.join(".dotfile")
    File.exists?(file).should be_true
    start
    File.open(file, 'w') { |f| f.write('') }
    stop
    results.should =~ ['spec/fixtures/.dotfile']
  end

  it "catches multiple file updates" do
    file1 = @fixture_path.join("folder1/file1.txt")
    file2 = @fixture_path.join("folder1/folder2/file2.txt")
    File.exists?(file1).should be_true
    File.exists?(file2).should be_true
    start
    File.open(file1, 'w') { |f| f.write('') }
    File.open(file2, 'w') { |f| f.write('') }
    stop
    results.should =~ ['spec/fixtures/folder1/file1.txt', 'spec/fixtures/folder1/folder2/file2.txt']
  end

  it "not catches a deleted file" do
    file = @fixture_path.join("folder1/file1.txt")
    File.exists?(file).should be_true
    start
    File.delete file
    stop
    FileUtils.touch file
    results.should =~ []
  end

  it "not catches a moved file" do
    file1 = @fixture_path.join("folder1/file1.txt")
    file2 = @fixture_path.join("folder1/movedfile1.txt")
    File.exists?(file1).should be_true
    File.exists?(file2).should be_false
    start
    FileUtils.mv file1, file2
    stop
    FileUtils.mv file2, file1
    results.should =~ []
  end

end

shared_examples_for "a listener scoped to a specific directory" do |rest_delay|
  before :each do
    @rest_delay = rest_delay if rest_delay.is_a?(Integer) || rest_delay.is_a?(Float) # jruby workaround
    @wd = @fixture_path.join("folder1")
    @listener = described_class.new @wd
  end

  it "should base paths within this directory" do
    record_results
    new_file = @wd.join("folder2/newfile.rb")
    modified = @wd.join("file1.txt")
    File.exists?(modified).should be_true
    File.exists?(new_file).should be_false
    start
    FileUtils.touch new_file
    File.open(modified, 'w') { |f| f.write('') }
    stop
    File.delete new_file
    results.should =~ ["folder2/newfile.rb", 'file1.txt']
  end
end

