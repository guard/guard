require 'spec_helper'
require 'guard/guard'

describe Guard::Watcher do
  
  describe "pattern" do
    it "should be required" do
      expect { Guard::Watcher.new }.to raise_error(ArgumentError)
    end
    
    it "can be a string" do
      Guard::Watcher.new('spec_helper.rb').pattern.should == 'spec_helper.rb'
    end
    
    it "can be a regexp" do
      Guard::Watcher.new(/spec_helper\.rb/).pattern.should == /spec_helper\.rb/
    end
    
    describe "string looking like a regex" do
      before(:each) { Guard::UI.should_receive(:info).any_number_of_times }
      
      specify { Guard::Watcher.new('^spec_helper.rb').pattern.should == /^spec_helper.rb/ }
      specify { Guard::Watcher.new('spec_helper.rb$').pattern.should == /spec_helper.rb$/ }
      specify { Guard::Watcher.new('spec_helper\.rb').pattern.should == /spec_helper\.rb/ }
      specify { Guard::Watcher.new('.*_spec.rb').pattern.should == /.*_spec.rb/ }
    end
  end
  
  describe "action" do
    it "should set action to nil by default" do
      Guard::Watcher.new(/spec_helper\.rb/).action.should be_nil
    end
    
    it "should set action with a block" do
      action = lambda { |m| "spec/#{m[1]}_spec.rb" }
      Guard::Watcher.new(%r{^lib/(.*).rb}, action).action.should == action
    end
  end
  
  describe ".match_files" do
    before(:all) { @guard = Guard::Guard.new }
    
    describe "a watcher's with no action" do
      before(:all) { @guard.watchers = [Guard::Watcher.new(/.*_spec\.rb/)] }
      
      it "should return paths as they came" do
        Guard::Watcher.match_files(@guard, ['guard_rocks_spec.rb']).should == ['guard_rocks_spec.rb']
      end
    end
    
    describe "a watcher's action with an arity equal to 0" do
      before(:all) do
        @guard.watchers = [
          Guard::Watcher.new(/spec_helper\.rb/, lambda { 'spec' }),
          Guard::Watcher.new(/addition\.rb/,    lambda { 1 + 1 }),
          Guard::Watcher.new(/hash\.rb/,        lambda { Hash[:foo, 'bar'] }),
          Guard::Watcher.new(/array\.rb/,       lambda { ['foo', 'bar'] }),
          Guard::Watcher.new(/blank\.rb/,       lambda { '' }),
          Guard::Watcher.new(/uptime\.rb/,      lambda { `uptime > /dev/null` })
        ]
      end
      
      it "should return paths specified in the watcher's action" do
        Guard::Watcher.match_files(@guard, ['spec_helper.rb']).should == ['spec']
      end
      it "should return nothing if action.call doesn't respond_to :empty?" do
        Guard::Watcher.match_files(@guard, ['addition.rb']).should == []
      end
      it "should return action.call.to_a if result respond_to :empty?" do
        Guard::Watcher.match_files(@guard, ['hash.rb']).should == ['foo', 'bar']
      end
      it "should return files including files from array if paths are an array" do
        Guard::Watcher.match_files(@guard, ['spec_helper.rb', 'array.rb']).should == ['spec', 'foo', 'bar']
      end
      it "should return nothing if action.call return ''" do
        Guard::Watcher.match_files(@guard, ['blank.rb']).should == []
      end
      it "should return nothing if action.call return nil" do
        Guard::Watcher.match_files(@guard, ['uptime.rb']).should == []
      end
    end
    
    describe "a watcher's action with an arity equal to 1" do
      before(:all) do
        @guard.watchers = [
          Guard::Watcher.new(%r{lib/(.*)\.rb},   lambda { |m| "spec/#{m[1]}_spec.rb" }),
          Guard::Watcher.new(/addition(.*)\.rb/, lambda { |m| 1 + 1 }),
          Guard::Watcher.new(/hash\.rb/,         lambda { Hash[:foo, 'bar'] }),
          Guard::Watcher.new(/array(.*)\.rb/,    lambda { |m| ['foo', 'bar'] }),
          Guard::Watcher.new(/blank(.*)\.rb/,    lambda { |m| '' }),
          Guard::Watcher.new(/uptime(.*)\.rb/,   lambda { |m| `uptime > /dev/null` })
        ]
      end
      
      it "should return paths after watcher's action has been called against them" do
        Guard::Watcher.match_files(@guard, ['lib/my_wonderful_lib.rb']).should == ['spec/my_wonderful_lib_spec.rb']
      end
      it "should return nothing if action.call doesn't respond_to :empty?" do
        Guard::Watcher.match_files(@guard, ['addition.rb']).should == []
      end
      it "should return action.call.to_a if result respond_to :empty?" do
        Guard::Watcher.match_files(@guard, ['hash.rb']).should == ['foo', 'bar']
      end
      it "should return files including files from array if paths are an array" do
        Guard::Watcher.match_files(@guard, ['lib/my_wonderful_lib.rb', 'array.rb']).should == ['spec/my_wonderful_lib_spec.rb', 'foo', 'bar']
      end
      it "should return nothing if action.call return ''" do
        Guard::Watcher.match_files(@guard, ['blank.rb']).should == []
      end
      it "should return nothing if action.call return nil" do
        Guard::Watcher.match_files(@guard, ['uptime.rb']).should == []
      end
    end
    
    describe "an exception is raised" do
      before(:all) { @guard.watchers = [Guard::Watcher.new('evil.rb', lambda { raise "EVIL" })] }
      
      it "should display an error" do
        Guard::UI.should_receive(:error).with("Problem with watch action!")
        Guard::Watcher.match_files(@guard, ['evil.rb'])
      end
    end
  end
  
  describe ".match_files?" do
    before(:all) do
      @guard1 = Guard::Guard.new([Guard::Watcher.new(/.*_spec\.rb/)])
      @guard2 = Guard::Guard.new([Guard::Watcher.new(/spec_helper\.rb/, 'spec')])
      @guards = [@guard1, @guard2]
    end
    
    describe "with at least on watcher that match a file given" do
      specify { Guard::Watcher.match_files?(@guards, ['lib/my_wonderful_lib.rb', 'guard_rocks_spec.rb']).should be_true }
    end
    
    describe "with no watcher matching a file given" do
      specify { Guard::Watcher.match_files?(@guards, ['lib/my_wonderful_lib.rb']).should be_false }
    end
  end
  
  describe "#match_file?" do
    describe "string pattern" do
      describe "normal string" do
        subject { Guard::Watcher.new('guard_rocks_spec.rb') }
        
        specify { subject.match_file?('lib/my_wonderful_lib.rb').should be_false }
        specify { subject.match_file?('guard_rocks_spec.rb').should be_true }
      end
      
      describe "string representing a regexp converted (while deprecation is active)" do
        subject { Guard::Watcher.new('^guard_rocks_spec\.rb$') }
        
        specify { subject.match_file?('lib/my_wonderful_lib.rb').should be_false }
        specify { subject.match_file?('guard_rocks_spec.rb').should be_true }
      end
    end
    
    describe "regexp pattern" do
      subject { Guard::Watcher.new(/.*_spec\.rb/) }
      
      specify { subject.match_file?('lib/my_wonderful_lib.rb').should be_false }
      specify { subject.match_file?('guard_rocks_spec.rb').should be_true }
    end
  end
  
end