require 'spec_helper'

describe Guard do
  
  describe "get_guard_class" do
    
    it "should return Guard::RSpec" do
      Guard.get_guard_class('rspec').should == Guard::RSpec
    end
    
  end
  
  describe "locate_guard" do
    
    it "should return guard-rspec gem path" do
      guard_path = Guard.locate_guard('rspec')
      guard_path.should match(/^.*\/guard-rspec-.*$/)
      guard_path.should == guard_path.chomp
    end
    
  end
  
end
