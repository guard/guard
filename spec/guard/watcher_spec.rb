require 'spec_helper'

describe Guard::Watcher do

  describe "#initialize" do
    it "requires a pattern parameter" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    context "with a pattern parameter" do
      context "that is a string" do
        it "keeps the string pattern unmodified" do
          described_class.new('spec_helper.rb').pattern.should == 'spec_helper.rb'
        end
      end

      context "that is a regexp" do
        it "keeps the regex pattern unmodified" do
          described_class.new(/spec_helper\.rb/).pattern.should == /spec_helper\.rb/
        end
      end

      context "that is a string looking like a regex (deprecated)" do
        before(:each) { Guard::UI.should_receive(:info).any_number_of_times }

        it "converts the string automatically to a regex" do
          described_class.new('^spec_helper.rb').pattern.should eq(/^spec_helper.rb/)
          described_class.new('spec_helper.rb$').pattern.should eq(/spec_helper.rb$/)
          described_class.new('spec_helper\.rb').pattern.should eq(/spec_helper\.rb/)
          described_class.new('.*_spec.rb').pattern.should eq(/.*_spec.rb/)
        end
      end
    end
  end

  describe "#action" do
    it "sets the action to nothing by default" do
      described_class.new(/spec_helper\.rb/).action.should be_nil
    end

    it "sets the action to the supplied block" do
      action = lambda { |m| "spec/#{m[1]}_spec.rb" }
      described_class.new(%r{^lib/(.*).rb}, action).action.should == action
    end
  end

  describe ".match_files" do
    before(:all) do
      @guard = Guard::Guard.new
      @guard_any_return = Guard::Guard.new
      @guard_any_return.options[:any_return] = true
    end

    context "with a watcher without action" do
      context "that is a regex pattern" do
        before(:all) { @guard.watchers = [described_class.new(/.*_spec\.rb/)] }

        it "returns the paths that matches the regex" do
          described_class.match_files(@guard, ['guard_rocks_spec.rb', 'guard_rocks.rb']).should == ['guard_rocks_spec.rb']
        end
      end

      context "that is a string pattern" do
        before(:all) { @guard.watchers = [described_class.new('guard_rocks_spec.rb')] }

        it "returns the path that matches the string" do
          described_class.match_files(@guard, ['guard_rocks_spec.rb', 'guard_rocks.rb']).should == ['guard_rocks_spec.rb']
        end
      end
    end

    context "with a watcher action without parameter" do
      context "for a watcher that matches file strings" do
        before(:all) do
          @guard.watchers = [
            described_class.new('spec_helper.rb', lambda { 'spec' }),
            described_class.new('addition.rb',    lambda { 1 + 1 }),
            described_class.new('hash.rb',        lambda { Hash[:foo, 'bar'] }),
            described_class.new('array.rb',       lambda { ['foo', 'bar'] }),
            described_class.new('blank.rb',       lambda { '' }),
            described_class.new(/^uptime\.rb/,    lambda { `uptime > /dev/null` })
          ]
        end

        it "returns a single file specified within the action" do
          described_class.match_files(@guard, ['spec_helper.rb']).should == ['spec']
        end

        it "returns multiple files specified within the action" do
          described_class.match_files(@guard, ['hash.rb']).should == ['foo', 'bar']
        end

        it "returns multiple files by combining the results of different actions" do
          described_class.match_files(@guard, ['spec_helper.rb', 'array.rb']).should == ['spec', 'foo', 'bar']
        end

        it "returns nothing if the action returns something other than a string or an array of strings" do
          described_class.match_files(@guard, ['addition.rb']).should == []
        end

        it "returns nothing if the action response is empty" do
          described_class.match_files(@guard, ['blank.rb']).should == []
        end

        it "returns nothing if the action returns nothing" do
          described_class.match_files(@guard, ['uptime.rb']).should == []
        end
      end

      context 'for a watcher that matches information objects' do
        before(:all) do
          @guard_any_return.watchers = [
            described_class.new('spec_helper.rb', lambda { 'spec' }),
            described_class.new('addition.rb',    lambda { 1 + 1 }),
            described_class.new('hash.rb',        lambda { Hash[:foo, 'bar'] }),
            described_class.new('array.rb',       lambda { ['foo', 'bar'] }),
            described_class.new('blank.rb',       lambda { '' }),
            described_class.new(/^uptime\.rb/,    lambda { `uptime > /dev/null` })
          ]
        end

        it "returns a single file specified within the action" do
          described_class.match_files(@guard_any_return, ['spec_helper.rb']).class.should be Array
          described_class.match_files(@guard_any_return, ['spec_helper.rb']).empty?.should be_false
        end

        it "returns multiple files specified within the action" do
          described_class.match_files(@guard_any_return, ['hash.rb']).should == [{:foo => 'bar'}]
        end

        it "returns multiple files by combining the results of different actions" do
          described_class.match_files(@guard_any_return, ['spec_helper.rb', 'array.rb']).should == ['spec', ['foo', 'bar']]
        end

        it "returns the evaluated addition argument in an array" do
          described_class.match_files(@guard_any_return, ['addition.rb']).class.should be Array
          described_class.match_files(@guard_any_return, ['addition.rb'])[0].should eq 2
        end

        it "returns nothing if the action response is empty string" do
          described_class.match_files(@guard_any_return, ['blank.rb']).should == ['']
        end

        it "returns nothing if the action returns empty string" do
          described_class.match_files(@guard_any_return, ['uptime.rb']).should == ['']
        end
      end
    end

    context "with a watcher action that takes a parameter" do
      context "for a watcher that matches file strings" do
         before(:all) do
           @guard.watchers = [
             described_class.new(%r{lib/(.*)\.rb},   lambda { |m| "spec/#{m[1]}_spec.rb" }),
             described_class.new(/addition(.*)\.rb/, lambda { |m| 1 + 1 }),
             described_class.new('hash.rb',          lambda { |m| Hash[:foo, 'bar'] }),
             described_class.new(/array(.*)\.rb/,    lambda { |m| ['foo', 'bar'] }),
             described_class.new(/blank(.*)\.rb/,    lambda { |m| '' }),
             described_class.new(/uptime(.*)\.rb/,   lambda { |m| `uptime > /dev/null` })
           ]
         end

         it "returns a substituted single file specified within the action" do
           described_class.match_files(@guard, ['lib/my_wonderful_lib.rb']).should == ['spec/my_wonderful_lib_spec.rb']
         end

         it "returns multiple files specified within the action" do
           described_class.match_files(@guard, ['hash.rb']).should == ['foo', 'bar']
         end

         it "returns multiple files by combining the results of different actions" do
           described_class.match_files(@guard, ['lib/my_wonderful_lib.rb', 'array.rb']).should == ['spec/my_wonderful_lib_spec.rb', 'foo', 'bar']
         end

         it "returns nothing if the action returns something other than a string or an array of strings" do
           described_class.match_files(@guard, ['addition.rb']).should == []
         end

         it "returns nothing if the action response is empty" do
           described_class.match_files(@guard, ['blank.rb']).should == []
         end

         it "returns nothing if the action returns nothing" do
           described_class.match_files(@guard, ['uptime.rb']).should == []
         end
      end

      context "for a watcher that matches information objects" do
        before(:all) do
          @guard_any_return.watchers = [
            described_class.new(%r{lib/(.*)\.rb},   lambda { |m| "spec/#{m[1]}_spec.rb" }),
            described_class.new(/addition(.*)\.rb/, lambda { |m| (1 + 1).to_s + m[0] }),
            described_class.new('hash.rb',          lambda { |m| Hash[:foo, 'bar', :file_name, m[0]] }),
            described_class.new(/array(.*)\.rb/,    lambda { |m| ['foo', 'bar', m[0]] }),
            described_class.new(/blank(.*)\.rb/,    lambda { |m| '' }),
            described_class.new(/uptime(.*)\.rb/,   lambda { |m| `uptime > /dev/null` })
          ]
        end

        it "returns a substituted single file specified within the action" do
          described_class.match_files(@guard_any_return, ['lib/my_wonderful_lib.rb']).should == ['spec/my_wonderful_lib_spec.rb']
        end

        it "returns a hash specified within the action" do
          described_class.match_files(@guard_any_return, ['hash.rb']).should == [{:foo => 'bar', :file_name => 'hash.rb'}]
        end

        it "returns multiple files by combining the results of different actions" do
          described_class.match_files(@guard_any_return, ['lib/my_wonderful_lib.rb', 'array.rb']).should == ['spec/my_wonderful_lib_spec.rb', ['foo', 'bar', "array.rb"]]
        end

        it "returns the evaluated addition argument + the path" do
          described_class.match_files(@guard_any_return, ['addition.rb']).should == ["2addition.rb"]
        end

        it "returns nothing if the action response is empty string" do
          described_class.match_files(@guard_any_return, ['blank.rb']).should == ['']
        end

        it "returns nothing if the action returns empty string" do
          described_class.match_files(@guard_any_return, ['uptime.rb']).should == ['']
        end
      end
    end

    context "with an exception that is raised" do
       before(:all) { @guard.watchers = [described_class.new('evil.rb', lambda { raise "EVIL" })] }

       it "displays the error and backtrace" do
         Guard::UI.should_receive(:error) do |msg|
           msg.should include("Problem with watch action!")
           msg.should include("EVIL")
         end

         described_class.match_files(@guard, ['evil.rb'])
       end
     end
   end

  describe ".match_files?" do
    before(:all) do
      @guard1 = Guard::Guard.new([described_class.new(/.*_spec\.rb/)])
      @guard2 = Guard::Guard.new([described_class.new('spec_helper.rb', 'spec')])
      @guards = [@guard1, @guard2]
    end

    context "with a watcher that matches a file" do
      specify { described_class.match_files?(@guards, ['lib/my_wonderful_lib.rb', 'guard_rocks_spec.rb']).should be_true }
    end

    context "with no watcher that matches a file" do
      specify { described_class.match_files?(@guards, ['lib/my_wonderful_lib.rb']).should be_false }
    end
  end

  describe ".match" do
    context "with a string pattern" do
      context "that is a normal string" do
        subject { described_class.new('guard_rocks_spec.rb') }

        context "with a watcher that matches a file" do
          specify { subject.match('guard_rocks_spec.rb').should eq ['guard_rocks_spec.rb'] }
        end

        context "with a file containing a $" do
          subject { described_class.new('lib$/guard_rocks_spec.rb') }

          specify { subject.match('lib$/guard_rocks_spec.rb').should eq ['lib$/guard_rocks_spec.rb'] }
        end

        context "with no watcher that matches a file" do
          specify { subject.match('lib/my_wonderful_lib.rb').should be_nil }
        end
      end

      context "that is a string representing a regexp (deprecated)" do
        subject { described_class.new('^guard_(rocks)_spec\.rb$') }

        context "with a watcher that matches a file" do
          specify { subject.match('guard_rocks_spec.rb').should eq ['guard_rocks_spec.rb', 'rocks'] }
        end

        context "with no watcher that matches a file" do
          specify { subject.match('lib/my_wonderful_lib.rb').should be_nil }
        end
      end
    end

    context "with a regexp pattern" do
      subject { described_class.new(/(.*)_spec\.rb/) }

      context "with a watcher that matches a file" do
        specify { subject.match('guard_rocks_spec.rb').should eq ['guard_rocks_spec.rb', 'guard_rocks'] }
      end

      context "with a file containing a $" do
        specify { subject.match('lib$/guard_rocks_spec.rb').should eq ['lib$/guard_rocks_spec.rb', 'lib$/guard_rocks'] }
      end

      context "with no watcher that matches a file" do
        specify { subject.match('lib/my_wonderful_lib.rb').should be_nil }
      end
    end

    context "path start with a !" do
      context "with a string pattern" do
        subject { described_class.new('guard_rocks_spec.rb') }

        context "with a watcher that matches a file" do
          specify { subject.match('!guard_rocks_spec.rb').should eq ['!guard_rocks_spec.rb'] }
        end

        context "with no watcher that matches a file" do
          specify { subject.match('!lib/my_wonderful_lib.rb').should be_nil }
        end
      end

      context "with a regexp pattern" do
        subject { described_class.new(/(.*)_spec\.rb/) }

        context "with a watcher that matches a file" do
          specify { subject.match('!guard_rocks_spec.rb').should eq ['!guard_rocks_spec.rb', 'guard_rocks'] }
        end

        context "with no watcher that matches a file" do
          specify { subject.match('!lib/my_wonderful_lib.rb').should be_nil }
        end
      end
    end
  end

  describe ".match_guardfile?" do
    before(:all) { Guard::Dsl.stub(:guardfile_path) { Dir.pwd + '/Guardfile' } }

    context "with files that match the Guardfile" do
      specify { described_class.match_guardfile?(['Guardfile', 'guard_rocks_spec.rb']).should be_true }
    end

    context "with no files that match the Guardfile" do
      specify { described_class.match_guardfile?(['guard_rocks.rb', 'guard_rocks_spec.rb']).should be_false }
    end
  end

end
