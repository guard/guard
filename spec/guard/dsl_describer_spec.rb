require 'spec_helper'

describe Guard::DslDescriber do
  before(:each) do
    ::Guard.stub!(:guards).and_return([mock('Guard')])
    user_config_path = File.expand_path(File.join('~', '.guard.rb'))
    File.stub(:exist?).with(user_config_path) { false }
  end
  subject { described_class }


  it 'should evaluate a Guardfile and create the right structure' do
    mixed_guardfile_string = <<-GUARD
guard 'test', :a => :b do
  watch('c')
end

group :a do
  guard 'test' do
    watch('c')
  end
end

group "b" do
  guard 'another' do
    watch('c')
  end
end
GUARD

    subject.evaluate_guardfile(:guardfile_contents => mixed_guardfile_string)

    subject.guardfile_structure.should == [
      { :guards => [ { :name => 'test', :options => { :a => :b } } ] },
      { :group => :a, :guards => [ { :name => 'test', :options => {} } ] },
      { :group => :b, :guards => [ { :name => 'another', :options => {} } ] }
    ]

  end
end
