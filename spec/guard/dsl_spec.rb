require 'spec_helper'

describe Guard::Dsl do
  subject { Guard::Dsl }

  before(:each) do
    ::Guard.stub!(:add_guard)
  end

  it "displays an error message when no Guardfile is found" do
    Dir.stub!(:pwd).and_return("no_guardfile_here")

    Guard::UI.should_receive(:error).with("No Guardfile in current folder, please create one.")
    lambda { subject.evaluate_guardfile }.should raise_error
  end

  it "displays an error message when Guardfile is not valid" do
    mock_guardfile_content("This Guardfile is invalid!")

    Guard::UI.should_receive(:error).with(/Invalid Guardfile, original error is:\n/)
    lambda { subject.evaluate_guardfile }.should raise_error
  end

  describe ".guardfile_include?" do
    it "detects a guard specified by a string with simple quotes" do
      mock_guardfile_content("guard 'test'")
      subject.guardfile_include?('test').should be_true
    end

    it "detects a guard specified by a string with double quotes" do
      mock_guardfile_content('guard "test"')
      subject.guardfile_include?('test').should be_true
    end

    it "detects a guard specified by a symbol" do
      mock_guardfile_content("guard :test")
      subject.guardfile_include?('test').should be_true
    end

    it "detects a guard wrapped in parentheses" do
      mock_guardfile_content("guard(:test)")
      subject.guardfile_include?('test').should be_true
    end
  end

  describe "#group" do
    before do
      mock_guardfile_content("
        group 'x' do
          guard 'test' do
            watch('c')
          end
        end

        group 'y' do
          guard 'another' do
            watch('c')
          end
        end")
    end

    it "should evaluates only the specified group" do
      ::Guard.should_receive(:add_guard).with('test', anything, {})
      ::Guard.should_not_receive(:add_guard).with('another', anything, {})
      subject.evaluate_guardfile(:group => ['x'])
    end

    it "should evaluates only the specified groups" do
      ::Guard.should_receive(:add_guard).with('test', anything, {})
      ::Guard.should_receive(:add_guard).with('another', anything, {})
      subject.evaluate_guardfile(:group => ['x', 'y'])
    end
  end

  describe "#guard" do
    it "should load a guard specified as a string from the DSL" do
      mock_guardfile_content("guard 'test'")

      ::Guard.should_receive(:add_guard).with('test', [], {})
      subject.evaluate_guardfile
    end

    it "should load a guard specified as a symbol from the DSL" do
      mock_guardfile_content("guard :test")

      ::Guard.should_receive(:add_guard).with(:test, [], {})
      subject.evaluate_guardfile
    end

    it "should receive options when specified" do
      mock_guardfile_content("guard 'test', :opt_a => 1, :opt_b => 'fancy'")

      ::Guard.should_receive(:add_guard).with('test', anything, { :opt_a => 1, :opt_b => 'fancy' })
      subject.evaluate_guardfile
    end
  end

  describe "#watch" do
    it "should receive watchers when specified" do
      mock_guardfile_content("
        guard 'test' do
          watch('a') { 'b' }
          watch('c')
        end")

      ::Guard.should_receive(:add_guard).with('test', anything, {}) do |name, watchers, options|
        watchers.size.should == 2
        watchers[0].pattern.should     == 'a'
        watchers[0].action.call.should == proc { 'b' }.call
        watchers[1].pattern.should     == 'c'
        watchers[1].action.should      be_nil
      end
      subject.evaluate_guardfile
    end
  end

private

  def mock_guardfile_content(content)
    File.stub!(:read).with(File.expand_path('../../../Guardfile', __FILE__)) { content }
  end

end
