require 'spec_helper'

describe Guard do
  
  describe "get_guard_class" do
    
    it "should return Guard::RSpec" do
      Guard.get_guard_class('rspec').should == Guard::RSpec
    end
    
  end
  
end
