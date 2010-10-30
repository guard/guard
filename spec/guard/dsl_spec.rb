require 'spec_helper'
require 'guard/dsl'

describe Guard::Dsl do
  subject {Guard::Dsl}
  
  it "load a guard from the DSL" do
    fixture :simple
    
    ::Guard.stub!(:add_guard)
    ::Guard.should_receive(:add_guard).with('test', [], {})
    subject.evaluate_guardfile
  end
  
  it "write an error message when no Guardfile is found" do
    fixture :no_guardfile
    
    Guard::UI.stub!(:error)
    Guard::UI.should_receive(:error).with("No Guardfile in current folder, please create one.")
    lambda { subject.evaluate_guardfile }.should raise_error
  end
  
  it "write an error message when Guardfile is not valid" do
    fixture :invalid_guardfile

    Guard::UI.stub!(:error)
    Guard::UI.should_receive(:error).with(/Invalid Guardfile, original error is:\n/)
    lambda { subject.evaluate_guardfile }.should raise_error
  end
  
  it "receive watchers when specified" do
    fixture :watchers
    
    ::Guard.stub!(:add_guard)
    ::Guard.should_receive(:add_guard).with('test', anything(), {}) do |name, watchers, options|
      watchers.size.should eql 2
    end
    subject.evaluate_guardfile
  end
  
  it "receive options when specified" do
    fixture :options
    
    ::Guard.stub!(:add_guard)
    ::Guard.should_receive(:add_guard).with('test', anything(), hash_including(:opt_a, :opt_b))
    subject.evaluate_guardfile
  end
  
private
  def fixture name
    ## Hack to make guard look into the correct fixture folder
    Dir.stub!(:pwd).and_return("#{@fixture_path}/dsl/#{name}")
    Dir.pwd.should == "#{@fixture_path}/dsl/#{name}"
  end
end
