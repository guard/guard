require 'spec_helper'
require 'guard/guard'

describe Guard do

  describe ".setup" do
    subject { ::Guard.setup }

    it "returns itself for chaining" do
      subject.should be ::Guard
    end

    it "initializes @guards" do
      subject.guards.should eql []
    end

    it "initializes @groups" do
      Guard.groups.should eql [:default]
    end

    it "initializes the options" do
      opts = { :my_opts => true }
      Guard.setup(opts).options.should include(:my_opts)
    end

    it "initializes the listener" do
      ::Guard.listener.should be_kind_of(Guard::Listener)
    end

    it "respect the watchdir option" do
      ::Guard.setup(:watchdir => "/foo/bar")
      ::Guard.listener.directory.should eql "/foo/bar"
    end

    it "turns on the notifier by default" do
      ENV["GUARD_NOTIFY"] = nil
      ::Guard::Notifier.should_receive(:turn_on)
      ::Guard.setup(:notify => true)
    end

    it "turns off the notifier if the notify option is false" do
      ::Guard::Notifier.should_receive(:turn_off)
      ::Guard.setup(:notify => false)
    end

    it "turns off the notifier if environment variable GUARD_NOTIFY is false" do
      ENV["GUARD_NOTIFY"] = 'false'
      ::Guard::Notifier.should_receive(:turn_off)
      ::Guard.setup(:notify => true)
    end

    it "logs command execution if the debug option is true" do
      ::Guard.should_receive(:debug_command_execution)
      ::Guard.setup(:debug => true)
    end
  end

  describe ".start" do
    it "basic check that core methods are called" do
      opts = { :my_opts => true, :guardfile => File.join(@fixture_path, "Guardfile") }
      ::Guard.should_receive(:setup).with(opts)
      ::Guard::Dsl.should_receive(:evaluate_guardfile).with(opts)
      ::Guard.listener.should_receive(:start)

      ::Guard.start(opts)
    end
  end

  describe ".add_guard" do
    before(:each) do
      @guard_rspec_class = double('Guard::RSpec')
      @guard_rspec = double('Guard::RSpec')

      Guard.stub!(:get_guard_class) { @guard_rspec_class }

      Guard.setup
    end

    it "accepts guard name as string" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      Guard.add_guard('rspec')
    end

    it "accepts guard name as symbol" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      Guard.add_guard(:rspec)
    end

    it "adds guard to the @guards array" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      Guard.add_guard(:rspec)

      Guard.guards.should eql [@guard_rspec]
    end

    context "with no watchers given" do
      it "gives an empty array of watchers" do
        @guard_rspec_class.should_receive(:new).with([], {}).and_return(@guard_rspec)

        Guard.add_guard(:rspec, [])
      end
    end

    context "with watchers given" do
      it "give the watchers array" do
        @guard_rspec_class.should_receive(:new).with([:foo], {}).and_return(@guard_rspec)

        Guard.add_guard(:rspec, [:foo])
      end
    end

    context "with no options given" do
      it "gives an empty hash of options" do
        @guard_rspec_class.should_receive(:new).with([], {}).and_return(@guard_rspec)

        Guard.add_guard(:rspec, [], [], {})
      end
    end

    context "with options given" do
      it "give the options hash" do
        @guard_rspec_class.should_receive(:new).with([], { :foo => true, :group => :backend }).and_return(@guard_rspec)

        Guard.add_guard(:rspec, [], [], { :foo => true, :group => :backend })
      end
    end
  end


  describe ".add_group" do
    before(:each) do
      Guard.setup
    end

    it "accepts group name as string" do
      Guard.add_group('backend')

      Guard.groups.should eql [:default, :backend]
    end

    it "accepts group name as symbol" do
      Guard.add_group(:backend)

      Guard.groups.should eql [:default, :backend]
    end
  end

  describe ".get_guard_class" do
    after do
      [:Classname, :DashedClassName, :Inline].each do |const|
        Guard.send(:remove_const, const) rescue nil
      end
    end

    it "reports an error if the class is not found" do
      ::Guard::UI.should_receive(:error).twice
      Guard.get_guard_class('notAGuardClass')
    end

    context 'with a nested Guard class' do
      it "resolves the Guard class from string" do
        Guard.should_receive(:require) { |classname|
          classname.should == 'guard/classname'
          class Guard::Classname
          end
        }
        Guard.get_guard_class('classname').should == Guard::Classname
      end

      it "resolves the Guard class from symbol" do
        Guard.should_receive(:require) { |classname|
          classname.should == 'guard/classname'
          class Guard::Classname
          end
        }
        Guard.get_guard_class(:classname).should == Guard::Classname
      end
    end

    context 'with a name with dashes' do
      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should == 'guard/dashed-class-name'
          class Guard::DashedClassName
          end
        }
        Guard.get_guard_class('dashed-class-name').should == Guard::DashedClassName
      end
    end

    context 'with an inline Guard class' do
      it 'returns the Guard class' do
        module Guard
          class Inline < Guard
          end
        end

        Guard.should_not_receive(:require)
        Guard.get_guard_class('inline').should == Guard::Inline
      end
    end
  end

  describe ".locate_guard" do
    it "returns the path of a Guard gem" do
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        gem_location = Gem::Specification.find_by_name("guard-rspec").full_gem_path
      else
        gem_location = Gem.source_index.find_name("guard-rspec").last.full_gem_path
      end

      Guard.locate_guard('rspec').should == gem_location
    end
  end

  describe ".guard_gem_names" do
    it "returns the list of guard gems" do
      gems = Guard.guard_gem_names
      gems.should include("rspec")
    end
  end

  describe ".supervised_task" do
    subject { ::Guard.setup }

    before(:each) do
      @g = mock(Guard::Guard).as_null_object
      subject.guards.push(@g)
    end

    context "with a task that succeed" do
      context 'without any arguments' do
        before(:each) do
          @g.stub!(:regular_without_arg) { true }
        end

        it "doesn't fire the Guard" do
          lambda { subject.supervised_task(@g, :regular_without_arg) }.should_not change(subject.guards, :size)
        end

        it "returns the result of the task" do
          ::Guard.supervised_task(@g, :regular_without_arg).should be_true
        end

        it "passes the args to the :begin hook" do
          @g.should_receive(:hook).with("regular_without_arg_begin", "given_path")
          ::Guard.supervised_task(@g, :regular_without_arg, "given_path")
        end

        it "passes the result of the supervised method to the :end hook" do
          @g.should_receive(:hook).with("regular_without_arg_begin", "given_path")
          @g.should_receive(:hook).with("regular_without_arg_end", true)
          ::Guard.supervised_task(@g, :regular_without_arg, "given_path")
        end
      end

      context 'with arguments' do
        before(:each) do
          @g.stub!(:regular_with_arg).with("given_path") { "I'm a success" }
        end

        it "doesn't fire the Guard" do
          lambda { subject.supervised_task(@g, :regular_with_arg, "given_path") }.should_not change(subject.guards, :size)
        end

        it "returns the result of the task" do
          ::Guard.supervised_task(@g, :regular_with_arg, "given_path").should eql "I'm a success"
        end

        it "calls the default begin hook but not the default end hook" do
          @g.should_receive(:hook).with("failing_begin")
          @g.should_not_receive(:hook).with("failing_end")
          ::Guard.supervised_task(@g, :failing)
        end
      end
    end

    context "with a task that raises an exception" do
      before(:each) { @g.stub!(:failing) { raise "I break your system" } }

      it "fires the Guard" do
        lambda { subject.supervised_task(@g, :failing) }.should change(subject.guards, :size).by(-1)
        subject.guards.should_not include(@g)
      end

      it "returns the exception" do
        failing_result = ::Guard.supervised_task(@g, :failing)
        failing_result.should be_kind_of(Exception)
        failing_result.message.should == 'I break your system'
      end
    end
  end

  describe ".debug_command_execution" do
    subject { ::Guard.setup }

    before do
      @original_system = Kernel.method(:system)
      @original_command = Kernel.method(:"`")
    end

    after do
      Kernel.send(:define_method, :system, @original_system.to_proc )
      Kernel.send(:define_method, :"`", @original_command.to_proc )
    end

    it "outputs Kernel.#system method parameters" do
      ::Guard.setup(:debug => true)
      ::Guard::UI.should_receive(:debug).with("Command execution: echo test")
      system("echo", "test").should be_true
    end

    it "outputs Kernel.#` method parameters" do
      ::Guard.setup(:debug => true)
      ::Guard::UI.should_receive(:debug).twice.with("Command execution: echo test")
      `echo test`.should eql "test\n"
      %x{echo test}.should eql "test\n"
    end

  end

end
