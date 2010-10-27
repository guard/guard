require 'spec_helper'

# mute UI
module Guard::UI
  class << self
    def info(message, options = {})
    end
    
    def error(message)
    end
    
    def debug(message)
    end
  end
end

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
  
  describe "init" do
    subject { ::Guard.init }
    
    it "Should retrieve itself for chaining" do
      subject.should be_kind_of Module
    end
    
    it "Should init guards array" do
      ::Guard.guards.should be_kind_of Array
    end
    
    it "Should init options" do
      opts = {:my_opts => true}
      ::Guard.init(opts).options.should be_include :my_opts
    end
    
    it "Should init listeners" do
      ::Guard.listener.should be_kind_of Guard::Listener
    end
  end
  
  describe "supervised_task" do
    subject {::Guard.init}
    
    before :each do
      @g = mock(Guard::Guard)
      @g.stub!(:regular).and_return { true }
      @g.stub!(:spy).and_return { raise "I break your system" }
      @g.stub!(:pirate).and_raise Exception.new("I blow your system up")
      @g.stub!(:regular_arg).with("given_path").and_return { "given_path" }
      subject.guards.push @g
    end
    
    it "should let it go when nothing special occurs" do
      subject.guards.should be_include @g
      subject.supervised_task(@g, :regular).should be_true
      subject.guards.should be_include @g
    end
    
    it "should let it work with some tools" do
      subject.guards.should be_include @g
      subject.supervised_task(@g, :regular).should be_true
      subject.guards.should be_include @g
    end
    
    it "should fire the guard on spy act discovery" do
      subject.guards.should be_include @g
      ::Guard.supervised_task(@g, :spy).should be_kind_of Exception
      subject.guards.should_not be_include @g
      ::Guard.supervised_task(@g, :spy).message.should == 'I break your system'
    end
    
    it "should fire the guard on pirate act discovery" do
      subject.guards.should be_include @g
      ::Guard.supervised_task(@g, :regular_arg, "given_path").should be_kind_of String
      subject.guards.should be_include @g
      ::Guard.supervised_task(@g, :regular_arg, "given_path").should == "given_path"
    end
  end
  
end
