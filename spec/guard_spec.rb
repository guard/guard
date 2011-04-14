require 'spec_helper'

describe Guard do

  describe "Class Methods" do
    describe ".setup" do
      subject { ::Guard.setup }

      it "should retrieve itself for chaining" do
        subject.should be_kind_of(Module)
      end

      it "should init guards array" do
        ::Guard.guards.should be_kind_of(Array)
      end

      it "should init options" do
        opts = { :my_opts => true }
        ::Guard.setup(opts).options.should include(:my_opts)
      end

      it "should init listener" do
        ::Guard.listener.should be_kind_of(Guard::Listener)
      end

      it "should turn off notifier if notify option is false" do
        ::Guard::Notifier.should_receive(:turn_off)
        ::Guard.setup(:notify => false)
      end
    end

    describe ".get_guard_class" do
      it "should report an error if the class is not found" do
        ::Guard::UI.should_receive(:error)
        Guard.get_guard_class('notAGuardClass')
      end

      context 'loaded some nested classes' do
        it "should find and return loaded class" do
          Guard.should_receive(:try_to_load_gem) { |className|
            className.should == 'classname'
            class Guard::Classname
            end
          }
          Guard.get_guard_class('classname').should == Guard::Classname
        end
      end

      context 'loaded some inline classes ' do
        it 'should return inline class' do
          module Guard
            class Inline < Guard
            end
          end

          Guard.get_guard_class('inline').should == Guard::Inline
        end
      end
    end

    describe ".locate_guard" do
      it "returns guard-rspec gem path" do
        guard_path = Guard.locate_guard('rspec')
        guard_path.should match(/^.*\/guard-rspec-.*$/)
        guard_path.should == guard_path.chomp
      end
    end

    describe ".supervised_task" do
      subject { ::Guard.setup }
      before(:each) do
        @g = mock(Guard::Guard).as_null_object
        subject.guards.push(@g)
      end

      describe "tasks that succeed" do
        before(:each) do
          @g.stub!(:regular) { true }
          @g.stub!(:regular_with_arg).with("given_path") { "i'm a success" }
        end

        it "doesn't fire the guard with a supervised method without argument" do
          lambda { subject.supervised_task(@g, :regular) }.should_not change(subject.guards, :size)
        end

        it "doesn't fire the guard with a supervised method with argument" do
          lambda { subject.supervised_task(@g, :regular_with_arg, "given_path") }.should_not change(subject.guards, :size)
        end

        it "returns the result of the supervised method" do
          ::Guard.supervised_task(@g, :regular).should be_true
          ::Guard.supervised_task(@g, :regular_with_arg, "given_path").should == "i'm a success"
        end
      end

      describe "tasks that raise an exception" do
        before(:each) { @g.stub!(:failing) { raise "I break your system" } }

        it "fires the guard" do
          lambda { subject.supervised_task(@g, :failing) }.should change(subject.guards, :size).by(-1)
          subject.guards.should_not include(@g)
        end

        it "returns the exception object" do
          failing_result = ::Guard.supervised_task(@g, :failing)
          failing_result.should be_kind_of(Exception)
          failing_result.message.should == 'I break your system'
        end
      end

      it "calls the default hooks"
    end

    describe ".locate_guard" do
      it "returns the path of the guard gem" do
        Guard.locate_guard('rspec').should == Gem.source_index.find_name("guard-rspec").last.full_gem_path
      end
    end
  end

end
