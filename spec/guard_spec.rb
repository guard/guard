require 'spec_helper'

describe Guard do
  
  describe "get_guard_class" do
    
    it "should return Guard::RSpec" do
      Guard.get_guard_class('rspec').should == Guard::RSpec
    end
    
  end
  
  describe "locate_guard" do
    
    it "should return guard-rspec pat" do
      Guard.locate_guard('rspec').should match(/^.*\/guard-rspec-.*$/)
    end
    
  end
  
end
