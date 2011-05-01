require 'spec_helper'
require 'guard/guard'

describe Guard::Dsl do
  subject { Guard::Dsl }

  class Guard::Dummy < Guard::Guard; end

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

    it "evaluates only the specified group" do
      ::Guard.should_receive(:add_guard).with('test', anything, anything, {})
      ::Guard.should_not_receive(:add_guard).with('another', anything, anything, {})
      subject.evaluate_guardfile(:group => ['x'])
    end

    it "evaluates only the specified groups" do
      ::Guard.should_receive(:add_guard).with('test', anything, anything, {})
      ::Guard.should_receive(:add_guard).with('another', anything, anything, {})
      subject.evaluate_guardfile(:group => ['x', 'y'])
    end
  end

  describe "#guard" do
    it "loads a guard specified by a string" do
      mock_guardfile_content("guard 'test'")
      ::Guard.should_receive(:add_guard).with('test', [], [], {})
      subject.evaluate_guardfile
    end

    it "loads a guard specified as a symbol from the DSL" do
      mock_guardfile_content("guard :test")
      ::Guard.should_receive(:add_guard).with(:test, [], [], {})
      subject.evaluate_guardfile
    end

    it "accepts options" do
      mock_guardfile_content("guard 'test', :opt_a => 1, :opt_b => 'fancy'")
      ::Guard.should_receive(:add_guard).with('test', anything, anything, { :opt_a => 1, :opt_b => 'fancy' })
      subject.evaluate_guardfile
    end
  end

  describe "#watch" do
    it "creates watchers for the guard" do
      mock_guardfile_content("
        guard 'test' do
          watch('a') { 'b' }
          watch('c')
        end")

      ::Guard.should_receive(:add_guard).with('test', anything, anything, {}) do |name, watchers, callbacks, options|
        watchers.should have(2).items
        watchers[0][:pattern].should     == 'a'
        watchers[0][:action].call.should == proc { 'b' }.call
        watchers[1][:pattern].should     == 'c'
        watchers[1][:action].should      be_nil
      end
      subject.evaluate_guardfile
    end
  end

  describe "#callback" do
    it "creates callbacks for the guard" do
      class MyCustomCallback
        def self.call(guard_class, event, args)
          # do nothing
        end
      end

      mock_guardfile_content('
        guard :dummy do
          callback(:start_end) { |guard_class, event, args| "#{guard_class} executed \'#{event}\' hook with #{args}!" }
          callback(MyCustomCallback, [:start_begin, :run_all_begin])
        end')

      ::Guard.should_receive(:add_guard).with(:dummy, anything, anything, {}) do |name, watchers, callbacks, options|
        callbacks.should have(2).items
        callbacks[0][:events].should   == :start_end
        callbacks[0][:listener].call(Guard::Dummy, :start_end, 'foo').should == "Guard::Dummy executed 'start_end' hook with foo!"
        callbacks[1][:events].should   == [:start_begin, :run_all_begin]
        callbacks[1][:listener].should == MyCustomCallback
      end
      subject.evaluate_guardfile
    end
  end

private

  def mock_guardfile_content(content)
    File.stub!(:read).with(File.expand_path('../../../Guardfile', __FILE__)) { content }
  end

end
