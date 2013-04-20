require 'spec_helper'

describe Guard do
  describe '#reload' do
    let(:runner) { stub(:run => true) }
    subject { ::Guard.setup }

    before do
      ::Guard.stub(:runner) { runner }
      ::Guard::Dsl.stub(:reevaluate_guardfile)
      ::Guard.stub(:within_preserved_state).and_yield
      ::Guard::UI.stub(:info)
      ::Guard::UI.stub(:clear)
    end

    it "clear UI" do
      ::Guard::UI.should_receive(:clear)
      subject.reload
    end

    context 'with a old scope format' do
      it 'does not re-evaluate the Guardfile' do
        ::Guard::Dsl.should_not_receive(:reevaluate_guardfile)
        subject.reload({ :group => :frontend })
      end

      it 'reloads Guard' do
        runner.should_receive(:run).with(:reload, { :groups => [:frontend] })
        subject.reload({ :group => :frontend })
      end
    end

    context 'with a new scope format' do
      it 'does not re-evaluate the Guardfile' do
        ::Guard::Dsl.should_not_receive(:reevaluate_guardfile)
        subject.reload({ :groups => [:frontend] })
      end

      it 'reloads Guard' do
        runner.should_receive(:run).with(:reload, { :groups => [:frontend] })
        subject.reload({ :groups => [:frontend] })
      end
    end

    context 'with an empty scope' do
      it 'does re-evaluate the Guardfile' do
        ::Guard::Dsl.should_receive(:reevaluate_guardfile)
        subject.reload
      end

      it 'does not reload Guard' do
        runner.should_not_receive(:run).with(:reload, { })
        subject.reload
      end
    end
  end

  describe ".guards" do
    before(:all) do
      class Guard::FooBar < Guard::Guard;
      end
      class Guard::FooBaz < Guard::Guard;
      end
    end

    after(:all) do
      ::Guard.instance_eval do
        remove_const(:FooBar)
        remove_const(:FooBaz)
      end
    end

    subject do
      guard                   = ::Guard.setup
      @guard_foo_bar_backend  = Guard::FooBar.new([], { :group => 'backend' })
      @guard_foo_bar_frontend = Guard::FooBar.new([], { :group => 'frontend' })
      @guard_foo_baz_backend  = Guard::FooBaz.new([], { :group => 'backend' })
      @guard_foo_baz_frontend = Guard::FooBaz.new([], { :group => 'frontend' })
      guard.instance_variable_get("@guards").push(@guard_foo_bar_backend)
      guard.instance_variable_get("@guards").push(@guard_foo_bar_frontend)
      guard.instance_variable_get("@guards").push(@guard_foo_baz_backend)
      guard.instance_variable_get("@guards").push(@guard_foo_baz_frontend)
      guard
    end

    it "return @guards without any argument" do
      subject.guards.should == subject.instance_variable_get("@guards")
    end

    context "find a guard by as string/symbol" do
      it "find a guard by a string" do
        subject.guards('foo-bar').should == @guard_foo_bar_backend
      end

      it "find a guard by a symbol" do
        subject.guards(:'foo-bar').should == @guard_foo_bar_backend
      end

      it "returns nil if guard is not found" do
        subject.guards('foo-foo').should be_nil
      end
    end

    context "find guards matching a regexp" do
      it "with matches" do
        subject.guards(/^foobar/).should == [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "without matches" do
        subject.guards(/foo$/).should == []
      end
    end

    context "find guards by their group" do
      it "group name is a string" do
        subject.guards(:group => 'backend').should == [@guard_foo_bar_backend, @guard_foo_baz_backend]
      end

      it "group name is a symbol" do
        subject.guards(:group => :frontend).should == [@guard_foo_bar_frontend, @guard_foo_baz_frontend]
      end

      it "returns [] if guard is not found" do
        subject.guards(:group => :unknown).should == []
      end
    end

    context "find guards by their group & name" do
      it "group name is a string" do
        subject.guards(:group => 'backend', :name => 'foo-bar').should == [@guard_foo_bar_backend]
      end

      it "group name is a symbol" do
        subject.guards(:group => :frontend, :name => :'foo-baz').should == [@guard_foo_baz_frontend]
      end

      it "returns [] if guard is not found" do
        subject.guards(:group => :unknown, :name => :'foo-baz').should == []
      end
    end
  end

  describe ".groups" do
    subject do
      guard           = ::Guard.setup
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    context 'without any argument' do
      it "return all groups" do
        subject.groups.should == subject.instance_variable_get("@groups")
      end
    end

    context "find a group by as string/symbol" do
      it "find a group by a string" do
        subject.groups('backend').should == @group_backend
      end

      it "find a group by a symbol" do
        subject.groups(:backend).should == @group_backend
      end

      it "returns nil if group is not found" do
        subject.groups(:foo).should be_nil
      end
    end

    context "find groups matching a regexp" do
      it "with matches" do
        subject.groups(/^back/).should == [@group_backend, @group_backflip]
      end

      it "without matches" do
        subject.groups(/back$/).should == []
      end
    end
  end


  describe ".setup_guards" do
    before(:all) {
      class Guard::FooBar < Guard::Guard;
      end }

    after(:all) do
      ::Guard.instance_eval { remove_const(:FooBar) }
    end

    subject do
      guard          = ::Guard.setup(:guardfile => File.join(@fixture_path, "Guardfile"))
      @group_backend = guard.add_guard(:foo_bar)
      guard
    end

    it "return @guards without any argument" do
      subject.guards.should have(1).item

      subject.setup_guards

      subject.guards.should be_empty
    end
  end

  describe ".start" do
    before do
      ::Guard.stub(:setup)
      ::Guard.stub(:listener => mock('listener', :start => true))
      ::Guard.stub(:runner => mock('runner', :run => true))
      ::Guard.stub(:within_preserved_state).and_yield
    end

    it "setup Guard" do
      ::Guard.should_receive(:setup).with(:foo => 'bar')

      ::Guard.start(:foo => 'bar')
    end

    it "displays an info message" do
      ::Guard.instance_variable_set('@watchdir', '/foo/bar')
      ::Guard::UI.should_receive(:info).with("Guard is now watching at '/foo/bar'")

      ::Guard.start
    end

    it "tell the runner to run the :start task" do
      ::Guard.runner.should_receive(:run).with(:start)

      ::Guard.start
    end

    it "start the listener" do
      ::Guard.listener.should_receive(:start)

      ::Guard.start
    end
  end

  describe ".stop" do
    before do
      ::Guard.stub(:setup)
      ::Guard.stub(:listener => mock('listener', :stop => true))
      ::Guard.stub(:runner => mock('runner', :run => true))
      ::Guard.stub(:within_preserved_state).and_yield
    end

    it "turns the notifier off" do
      ::Guard::Notifier.should_receive(:turn_off)

      ::Guard.stop
    end

    it "tell the runner to run the :stop task" do
      ::Guard.runner.should_receive(:run).with(:stop)

      ::Guard.stop
    end

    it "stops the listener" do
      ::Guard.listener.should_receive(:stop)

      ::Guard.stop
    end

    it "sets the running state to false" do
      ::Guard.running = true
      ::Guard.stop
      ::Guard.running.should be_false
    end
  end

  describe ".add_guard" do
    before do
      @guard_rspec_class = double('Guard::RSpec')
      @guard_rspec       = double('Guard::RSpec', :is_a? => true)

      ::Guard.stub!(:get_guard_class) { @guard_rspec_class }

      ::Guard.setup_guards
      ::Guard.setup_groups
      ::Guard.add_group(:backend)
    end

    it "accepts guard name as string" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      ::Guard.add_guard('rspec')
    end

    it "accepts guard name as symbol" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      ::Guard.add_guard(:rspec)
    end

    it "adds guard to the @guards array" do
      @guard_rspec_class.should_receive(:new).and_return(@guard_rspec)

      ::Guard.add_guard(:rspec)

      ::Guard.guards.should eq [@guard_rspec]
    end

    context "with no watchers given" do
      it "gives an empty array of watchers" do
        @guard_rspec_class.should_receive(:new).with([], { }).and_return(@guard_rspec)

        ::Guard.add_guard(:rspec, [])
      end
    end

    context "with watchers given" do
      it "give the watchers array" do
        @guard_rspec_class.should_receive(:new).with([:foo], { }).and_return(@guard_rspec)

        ::Guard.add_guard(:rspec, [:foo])
      end
    end

    context "with no options given" do
      it "gives an empty hash of options" do
        @guard_rspec_class.should_receive(:new).with([], { }).and_return(@guard_rspec)

        ::Guard.add_guard(:rspec, [], [], { })
      end
    end

    context "with options given" do
      it "give the options hash" do
        @guard_rspec_class.should_receive(:new).with([], { :foo => true, :group => :backend }).and_return(@guard_rspec)

        ::Guard.add_guard(:rspec, [], [], { :foo => true, :group => :backend })
      end
    end
  end

  describe ".add_group" do
    before { ::Guard.setup_groups }

    it "accepts group name as string" do
      ::Guard.add_group('backend')

      ::Guard.groups[0].name.should == :default
      ::Guard.groups[1].name.should == :backend
    end

    it "accepts group name as symbol" do
      ::Guard.add_group(:backend)

      ::Guard.groups[0].name.should == :default
      ::Guard.groups[1].name.should == :backend
    end

    it "accepts options" do
      ::Guard.add_group(:backend, { :halt_on_fail => true })

      ::Guard.groups[0].options.should eq({ })
      ::Guard.groups[1].options.should eq({ :halt_on_fail => true })
    end
  end

  describe '.within_preserved_state' do
    subject { ::Guard.setup }
    before { subject.interactor = stub('interactor').as_null_object }

    it 'disallows running the block concurrently to avoid inconsistent states' do
      subject.lock.should_receive(:synchronize)
      subject.within_preserved_state &Proc.new { }
    end

    it 'runs the passed block' do
      @called = false
      subject.within_preserved_state { @called = true }
      @called.should be_true
    end

    context 'with restart interactor enabled' do
      it 'stops the interactor before running the block and starts it again when done' do
        subject.interactor.should_receive(:stop)
        subject.interactor.should_receive(:start)
        subject.within_preserved_state &Proc.new { }
      end
    end

    context 'without restart interactor enabled' do
      it 'stops the interactor before running the block' do
        subject.interactor.should_receive(:stop)
        subject.interactor.should__not_receive(:start)
        subject.within_preserved_state &Proc.new { }
      end
    end
  end

  describe ".get_guard_class" do
    after do
      [:Classname, :DashedClassName, :UnderscoreClassName, :VSpec, :Inline].each do |const|
        Guard.send(:remove_const, const) rescue nil
      end
    end

    it "reports an error if the class is not found" do
      ::Guard::UI.should_receive(:error).twice
      Guard.get_guard_class('notAGuardClass')
    end

    context 'with a nested Guard class' do
      after(:all) { Guard.instance_eval { remove_const(:Classname) } rescue nil }

      it "resolves the Guard class from string" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname;
          end
        }
        Guard.get_guard_class('classname').should == Guard::Classname
      end

      it "resolves the Guard class from symbol" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname;
          end
        }
        Guard.get_guard_class(:classname).should == Guard::Classname
      end
    end

    context 'with a name with dashes' do
      after(:all) { Guard.instance_eval { remove_const(:DashedClassName) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/dashed-class-name'
          class Guard::DashedClassName;
          end
        }
        Guard.get_guard_class('dashed-class-name').should == Guard::DashedClassName
      end
    end

    context 'with a name with underscores' do
      after(:all) { Guard.instance_eval { remove_const(:UnderscoreClassName) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/underscore_class_name'
          class Guard::UnderscoreClassName;
          end
        }
        Guard.get_guard_class('underscore_class_name').should == Guard::UnderscoreClassName
      end
    end

    context 'with a name where its class does not follow the strict case rules' do
      after(:all) { Guard.instance_eval { remove_const(:VSpec) } rescue nil }

      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/vspec'
          class Guard::VSpec;
          end
        }
        Guard.get_guard_class('vspec').should == Guard::VSpec
      end
    end

    context 'with an inline Guard class' do
      after(:all) { Guard.instance_eval { remove_const(:Inline) } rescue nil }

      it 'returns the Guard class' do
        module Guard
          class Inline < Guard
          end
        end

        Guard.should_not_receive(:require)
        Guard.get_guard_class('inline').should == Guard::Inline
      end
    end

    context 'when set to fail gracefully' do
      it 'does not print error messages on fail' do
        ::Guard::UI.should_not_receive(:error)
        Guard.get_guard_class('notAGuardClass', true).should be_nil
      end
    end
  end

  let!(:rubygems_version_1_7_2) { Gem::Version.create('1.7.2') }
  let!(:rubygems_version_1_8_0) { Gem::Version.create('1.8.0') }

  describe '.locate_guard' do
    context 'Rubygems < 1.8.0' do
      before do
        Gem::Version.should_receive(:create).with(Gem::VERSION) { rubygems_version_1_7_2 }
        Gem::Version.should_receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
      end

      it "returns the path of a Guard gem" do
        gems_source_index = stub
        gems_found = [stub(:full_gem_path => 'gems/guard-rspec')]
        Gem.should_receive(:source_index) { gems_source_index }
        gems_source_index.should_receive(:find_name).with('guard-rspec') { gems_found }

        Guard.locate_guard('rspec').should eq 'gems/guard-rspec'
      end
    end

    context 'Rubygems >= 1.8.0' do
      before do
        Gem::Version.should_receive(:create).with(Gem::VERSION) { rubygems_version_1_8_0 }
        Gem::Version.should_receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
      end

      it "returns the path of a Guard gem" do
        Gem::Specification.should_receive(:find_by_name).with('guard-rspec') { stub(:full_gem_path => 'gems/guard-rspec') }

        Guard.locate_guard('rspec').should eq 'gems/guard-rspec'
      end
    end
  end

  describe '.guard_gem_names' do
    context 'Rubygems < 1.8.0' do
      before do
        Gem::Version.should_receive(:create).with(Gem::VERSION) { rubygems_version_1_7_2 }
        Gem::Version.should_receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
        gems_source_index = stub
        Gem.should_receive(:source_index) { gems_source_index }
        gems_source_index.should_receive(:find_name).with(/^guard-/) { [stub(:name => 'guard-rspec')] }
      end

      it 'returns the list of guard gems' do
        Guard.guard_gem_names.should include('rspec')
      end
    end

    context 'Rubygems >= 1.8.0' do
      before do
        Gem::Version.should_receive(:create).with(Gem::VERSION) { rubygems_version_1_8_0 }
        Gem::Version.should_receive(:create).with('1.8.0') { rubygems_version_1_8_0 }
        gems = [
          stub(:name => 'guard'),
          stub(:name => 'guard-rspec'),
          stub(:name => 'gem1', :full_gem_path => '/gem1'),
          stub(:name => 'gem2', :full_gem_path => '/gem2'),
        ]
        File.stub(:exists?).with('/gem1/lib/guard/gem1.rb') { false }
        File.stub(:exists?).with('/gem2/lib/guard/gem2.rb') { true }
        Gem::Specification.should_receive(:find_all) { gems }
      end

      it "returns the list of guard gems" do
        gems = Guard.guard_gem_names
        gems.should include('rspec')
      end

      it "returns the list of embedded guard gems" do
        gems = Guard.guard_gem_names
        gems.should include('gem2')
      end
    end
  end

  describe ".debug_command_execution" do
    subject { ::Guard.setup }

    before do
      Guard.unstub(:debug_command_execution)
      @original_system  = Kernel.method(:system)
      @original_command = Kernel.method(:"`")
    end

    after do
      Kernel.send(:remove_method, :system, :'`')
      Kernel.send(:define_method, :system, @original_system.to_proc)
      Kernel.send(:define_method, :"`", @original_command.to_proc)
      Guard.stub(:debug_command_execution)
    end

    it "outputs Kernel.#system method parameters" do
      ::Guard::UI.should_receive(:debug).with("Command execution: exit 0")
      ::Guard.setup(:debug => true)
      system("exit", "0").should be_false
    end

    it "outputs Kernel.#` method parameters" do
      ::Guard::UI.should_receive(:debug).with("Command execution: echo test")
      ::Guard.setup(:debug => true)
      `echo test`.should == "test\n"
    end

    it "outputs %x{} method parameters" do
      ::Guard::UI.should_receive(:debug).with("Command execution: echo test")
      ::Guard.setup(:debug => true)
      %x{echo test}.should == "test\n"
    end

  end

end
