require 'spec_helper'
require 'guard/guard'

describe Guard do

  it "has a valid Guardfile template" do
    File.exists?(Guard::GUARDFILE_TEMPLATE).should be_true
  end

  describe ".create_guardfile" do
    before { Dir.stub(:pwd).and_return "/home/user" }

    context "with an existing Guardfile" do
      before { File.should_receive(:exist?).and_return true }

      it "does not copy the Guardfile template or notify the user" do
        ::Guard::UI.should_not_receive(:info).with('Writing new Guardfile to /home/user/Guardfile')
        FileUtils.should_not_receive(:cp).with(an_instance_of(String), 'Guardfile')

        subject.create_guardfile
      end
    end

    context "without an existing Guardfile" do
      before { File.should_receive(:exist?).and_return false }

      it "copies the Guardfile template and notifies the user" do
        ::Guard::UI.should_receive(:info)
        FileUtils.should_receive(:cp)

        subject.create_guardfile
      end
    end
  end

  describe ".initialize_template" do
    context 'with an installed Guard implementation' do
      let(:foo_guard) { double('Guard::Foo').as_null_object }

      before { ::Guard.should_receive(:get_guard_class).and_return(foo_guard) }

      it "initializes the Guard" do
        foo_guard.should_receive(:init)
        subject.initialize_template('foo')
      end
    end

    context "with a user defined template" do
      let(:template) { File.join(Guard::HOME_TEMPLATES, '/bar') }

      before { File.should_receive(:exist?).with(template).and_return true }

      it "copies the Guardfile template and initializes the Guard" do
        File.should_receive(:read).with('Guardfile').and_return 'Guardfile content'
        File.should_receive(:read).with(template).and_return 'Template content'
        io = StringIO.new
        File.should_receive(:open).with('Guardfile', 'wb').and_yield io
        subject.initialize_template('bar')
        io.string.should eql "Guardfile content\n\nTemplate content\n"
      end
    end

    context "when the passed guard can't be found" do
      before { File.should_receive(:exist?).and_return false }

      it "notifies the user about the problem" do
        ::Guard::UI.should_receive(:error).with(
          "Could not load 'guard/foo' or '~/.guard/templates/foo' or find class Guard::Foo"
        )
        subject.initialize_template('foo')
      end
    end
  end

  describe ".initialize_all_templates" do
    let(:guards) { ['rspec', 'spork', 'phpunit'] }

    before { subject.should_receive(:guard_gem_names).and_return(guards) }

    it "calls Guard.initialize_template on all installed guards" do
      guards.each do |g|
        subject.should_receive(:initialize_template).with(g)
      end

      subject.initialize_all_templates
    end
  end

  describe ".setup" do
    subject { ::Guard.setup }

    it "returns itself for chaining" do
      subject.should be ::Guard
    end

    it "initializes @guards" do
      subject.guards.should eql []
    end

    it "initializes @groups" do
      subject.groups[0].name.should eql :default
      subject.groups[0].options.should == {}
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

    it "logs command execution if the debug option is true" do
      ::Guard.should_receive(:debug_command_execution)
      ::Guard.setup(:verbose => true)
    end
  end

  describe ".guards" do

    class Guard::FooBar < Guard::Guard; end
    class Guard::FooBaz < Guard::Guard; end

    subject do
      guard = ::Guard.setup
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
      subject.guards.should eql subject.instance_variable_get("@guards")
    end

    describe "find a guard by as string/symbol" do
      it "find a guard by a string" do
        subject.guards('foo-bar').should eql @guard_foo_bar_backend
      end

      it "find a guard by a symbol" do
        subject.guards(:'foo-bar').should eql @guard_foo_bar_backend
      end

      it "returns nil if guard is not found" do
        subject.guards('foo-foo').should be_nil
      end
    end

    describe "find guards matching a regexp" do
      it "with matches" do
        subject.guards(/^foobar/).should eql [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "without matches" do
        subject.guards(/foo$/).should eql []
      end
    end

    describe "find guards by their group" do
      it "group name is a string" do
        subject.guards(:group => 'backend').should eql [@guard_foo_bar_backend, @guard_foo_baz_backend]
      end

      it "group name is a symbol" do
        subject.guards(:group => :frontend).should eql [@guard_foo_bar_frontend, @guard_foo_baz_frontend]
      end

      it "returns [] if guard is not found" do
        subject.guards(:group => :unknown).should eql []
      end
    end

    describe "find guards by their group & name" do
      it "group name is a string" do
        subject.guards(:group => 'backend', :name => 'foo-bar').should eql [@guard_foo_bar_backend]
      end

      it "group name is a symbol" do
        subject.guards(:group => :frontend, :name => :'foo-baz').should eql [@guard_foo_baz_frontend]
      end

      it "returns [] if guard is not found" do
        subject.guards(:group => :unknown, :name => :'foo-baz').should eql []
      end
    end
  end

  describe ".groups" do
    subject do
      guard = ::Guard.setup
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    it "return @groups without any argument" do
      subject.groups.should eql subject.instance_variable_get("@groups")
    end

    describe "find a group by as string/symbol" do
      it "find a group by a string" do
        subject.groups('backend').should eql @group_backend
      end

      it "find a group by a symbol" do
        subject.groups(:backend).should eql @group_backend
      end

      it "returns nil if group is not found" do
        subject.groups(:foo).should be_nil
      end
    end

    describe "find groups matching a regexp" do
      it "with matches" do
        subject.groups(/^back/).should eql [@group_backend, @group_backflip]
      end

      it "without matches" do
        subject.groups(/back$/).should eql []
      end
    end
  end

  describe ".reset_groups" do
    subject do
      guard = ::Guard.setup
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    it "return @groups without any argument" do
      subject.groups.should have(3).items

      subject.reset_groups

      subject.groups.should have(1).item
      subject.groups[0].name.should eql :default
      subject.groups[0].options.should == {}
    end
  end

  describe ".start" do
    let(:options) { { :my_opts => true, :guardfile => File.join(@fixture_path, "Guardfile") } }

    before do
      Guard.stub(:setup)
      Guard.listener.stub(:start)
      Guard::Dsl.stub(:evaluate_guardfile)
      Guard::Notifier.stub(:turn_on)
      Guard::Notifier.stub(:turn_off)
    end

    it "setup Guard" do
      ::Guard.should_receive(:setup).with(options)
      ::Guard.start(options)
    end

    it "evaluates the DSL" do
      ::Guard::Dsl.should_receive(:evaluate_guardfile).with(options)
      ::Guard.start(options)
    end

    it "displays an error message when no guard are defined in Guardfile" do
      ::Guard::Dsl.should_receive(:evaluate_guardfile).with(options)
      ::Guard::UI.should_receive(:error)
      ::Guard.start(options)
    end

    it "starts the listeners" do
      ::Guard.listener.should_receive(:start)
      ::Guard.start(options)
    end

    context "with interactions enabled" do
      it "fabricates the interactor" do
        ::Guard::Interactor.should_receive(:fabricate)
        ::Guard.start(:no_interactions => false)
      end

      it "starts the interactor" do
        interactor = mock('interactor')
        interactor.should_receive(:start)
        ::Guard::Interactor.should_receive(:fabricate).and_return interactor
        ::Guard.start(:no_interactions => false)
      end
    end

    context "with interactions disabled" do
      it "fabricates the interactor" do
        ::Guard::Interactor.should_not_receive(:fabricate)
        ::Guard.start(:no_interactions => true)
      end
    end

    context "with the notify option enabled" do
      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV["GUARD_NOTIFY"] = nil }

        it "turns on the notifier on" do
          ::Guard::Notifier.should_receive(:turn_on)
          ::Guard.start(:notify => true)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV["GUARD_NOTIFY"] = 'true' }

        it "turns on the notifier on" do
          ::Guard::Notifier.should_receive(:turn_on)
          ::Guard.start(:notify => true)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV["GUARD_NOTIFY"] = 'false' }

        it "turns on the notifier off" do
          ::Guard::Notifier.should_receive(:turn_off)
          ::Guard.start(:notify => true)
        end
      end
    end

    context "with the notify option disable" do
      context 'without the environment variable GUARD_NOTIFY set' do
        before { ENV["GUARD_NOTIFY"] = nil }

        it "turns on the notifier off" do
          ::Guard::Notifier.should_receive(:turn_off)
          ::Guard.start(:notify => false)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to true' do
        before { ENV["GUARD_NOTIFY"] = 'true' }

        it "turns on the notifier on" do
          ::Guard::Notifier.should_receive(:turn_off)
          ::Guard.start(:notify => false)
        end
      end

      context 'with the environment variable GUARD_NOTIFY set to false' do
        before { ENV["GUARD_NOTIFY"] = 'false' }

        it "turns on the notifier off" do
          ::Guard::Notifier.should_receive(:turn_off)
          ::Guard.start(:notify => false)
        end
      end
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
    subject { ::Guard.setup }

    it "accepts group name as string" do
      subject.add_group('backend')

      subject.groups[0].name.should eql :default
      subject.groups[1].name.should eql :backend
    end

    it "accepts group name as symbol" do
      subject.add_group(:backend)

      subject.groups[0].name.should eql :default
      subject.groups[1].name.should eql :backend
    end

    it "accepts options" do
      subject.add_group(:backend, { :halt_on_fail => true })

      subject.groups[0].options.should eq({})
      subject.groups[1].options.should eq({ :halt_on_fail => true })
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
      it "resolves the Guard class from string" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname
          end
        }
        Guard.get_guard_class('classname').should == Guard::Classname
      end

      it "resolves the Guard class from symbol" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/classname'
          class Guard::Classname
          end
        }
        Guard.get_guard_class(:classname).should == Guard::Classname
      end
    end

    context 'with a name with dashes' do
      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/dashed-class-name'
          class Guard::DashedClassName
          end
        }
        Guard.get_guard_class('dashed-class-name').should == Guard::DashedClassName
      end
    end

    context 'with a name with underscores' do
      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/underscore_class_name'
          class Guard::UnderscoreClassName
          end
        }
        Guard.get_guard_class('underscore_class_name').should == Guard::UnderscoreClassName
      end
    end

    context 'with a name where its class does not follow the strict case rules' do
      it "returns the Guard class" do
        Guard.should_receive(:require) { |classname|
          classname.should eq 'guard/vspec'
          class Guard::VSpec
          end
        }
        Guard.get_guard_class('vspec').should == Guard::VSpec
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

    context 'when set to fail gracefully' do
      it 'does not print error messages on fail' do
        ::Guard::UI.should_not_receive(:error)
        Guard.get_guard_class('notAGuardClass', true).should be_nil
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

  describe ".run_on_guards" do
    subject { ::Guard.setup }

    before do
      class Guard::Dummy < Guard::Guard; end
      class Guard::Dumby < Guard::Guard; end

      @foo_group = subject.add_group(:foo, { :halt_on_fail => true })
      subject.add_group(:bar)
      subject.add_guard(:dummy, [], [], { :group => :foo })
      subject.add_guard(:dummy, [], [], { :group => :foo })
      @dumby_guard = subject.add_guard(:dumby, [], [], { :group => :bar })
      subject.add_guard(:dummy, [], [], { :group => :bar })
      @sum = { :foo => 0, :bar => 0 }
    end

    context "all tasks succeed" do
      before do
        subject.guards.each { |guard| guard.stub!(:task) { @sum[guard.group] += 1; true } }
      end

      it "executes the task for each guard in each group" do
        subject.run_on_guards do |guard|
          guard.task
        end

        @sum.all? { |k, v| v == 2 }.should be_true
      end

      it "executes the task for each guard in foo group only" do
        subject.run_on_guards(:group => @foo_group) do |guard|
          guard.task
        end

        @sum[:foo].should eq 2
        @sum[:bar].should eq 0
      end

      it "executes the task for dumby guard only" do
        subject.run_on_guards(:guard => @dumby_guard) do |guard|
          guard.task
        end

        @sum[:foo].should eq 0
        @sum[:bar].should eq 1
      end
    end

    context "one guard fails" do
      before do
        subject.guards.each_with_index do |guard, i|
          guard.stub!(:task) do
            @sum[guard.group] += i+1
            if i % 2 == 0
              throw :task_has_failed
            else
              true
            end
          end
        end
      end

      it "executes the task only for guards that didn't fail for group with :halt_on_fail == true" do
        subject.run_on_guards do |guard|
          subject.run_supervised_task(guard, :task)
        end

        @sum[:foo].should eql 1
        @sum[:bar].should eql 7
      end
    end
  end

  describe ".run_on_change_task" do
    let(:guard) do
      guard = mock(Guard::Guard).as_null_object
      guard.stub!(:watchers) { [Guard::Watcher.new(/.+\.rb/)] }

      guard
    end

    it 'runs the :run_on_change task with the watched file changes' do
      Guard.should_receive(:run_supervised_task).with(guard, :run_on_change, ['a.rb', 'b.rb'])
      Guard.run_on_change_task(['a.rb', 'b.rb', 'templates/d.haml'], guard)
    end

    it 'runs the :run_on_deletion task with the watched file deletions' do
      Guard.should_receive(:run_supervised_task).with(guard, :run_on_deletion, ['c.rb'])
      Guard.run_on_change_task(['!c.rb', '!templates/e.haml'], guard)
    end
  end

  describe ".changed_paths" do
    context 'for an array with string paths' do
      let(:paths) { ['a.rb', 'b.rb', '!c.rb', 'templates/d.haml', '!templates/e.haml'] }

      it 'returns the changed paths' do
        Guard.changed_paths(paths).should =~ ['a.rb', 'b.rb', 'templates/d.haml']
      end
    end

    context 'for an array with objects that do not respond to .start_with (any_return option)' do
      let(:paths) { [42, 'a.rb', [1], '!c.rb', 'templates/d.haml', '!templates/e.haml', { :a => 1 }] }

      it 'returns the changed paths and the objects' do
        Guard.changed_paths(paths).should =~ [42, 'a.rb', [1], 'templates/d.haml', { :a => 1 }]
      end
    end
  end

  describe ".deleted_paths" do
    context 'for an array with string' do
      let(:paths) { ['a.rb', 'b.rb', '!c.rb', 'templates/d.haml', '!templates/e.haml'] }

      it 'returns the deleted paths' do
        Guard.deleted_paths(paths).should =~ ['c.rb', 'templates/e.haml']
      end
    end

    context 'for an array with objects that do not respond to .start_with (any_return option)' do
      let(:paths) { [42, 'a.rb', [1], '!c.rb', 'templates/d.haml', '!templates/e.haml', { :a => 1 }] }

      it 'returns the deleted paths' do
        Guard.deleted_paths(paths).should =~ ['c.rb', 'templates/e.haml']
      end
    end
  end

  describe ".run_supervised_task" do
    subject { ::Guard.setup }

    before do
      @g = mock(Guard::Guard).as_null_object
      subject.guards.push(@g)
      subject.add_group(:foo, { :halt_on_fail => true })
      subject.add_group(:bar, { :halt_on_fail => false })
    end

    context "with a task that succeed" do
      context 'without any arguments' do
        before(:each) do
          @g.stub!(:regular_without_arg) { true }
        end

        it "doesn't fire the Guard" do
          lambda { subject.run_supervised_task(@g, :regular_without_arg) }.should_not change(subject.guards, :size)
        end

        it "returns the result of the task" do
          ::Guard.run_supervised_task(@g, :regular_without_arg).should be_true
        end

        it "passes the args to the :begin hook" do
          @g.should_receive(:hook).with("regular_without_arg_begin", "given_path")
          ::Guard.run_supervised_task(@g, :regular_without_arg, "given_path")
        end

        it "passes the result of the supervised method to the :end hook" do
          @g.should_receive(:hook).with("regular_without_arg_begin", "given_path")
          @g.should_receive(:hook).with("regular_without_arg_end", true)
          ::Guard.run_supervised_task(@g, :regular_without_arg, "given_path")
        end
      end

      context 'with arguments' do
        before(:each) do
          @g.stub!(:regular_with_arg).with("given_path") { "I'm a success" }
        end

        it "doesn't fire the Guard" do
          lambda { subject.run_supervised_task(@g, :regular_with_arg, "given_path") }.should_not change(subject.guards, :size)
        end

        it "returns the result of the task" do
          ::Guard.run_supervised_task(@g, :regular_with_arg, "given_path").should eql "I'm a success"
        end

        it "calls the default begin hook but not the default end hook" do
          @g.should_receive(:hook).with("failing_begin")
          @g.should_not_receive(:hook).with("failing_end")
          ::Guard.run_supervised_task(@g, :failing)
        end
      end
    end

    context "with a task that throw :task_has_failed" do
      context "for a guard's group has the :halt_on_fail option == true" do
        before(:each) { @g.stub!(:group) { :foo }; @g.stub!(:failing) { throw :task_has_failed } }

        it "throws :task_has_failed" do
          expect { subject.run_supervised_task(@g, :failing) }.to throw_symbol(:task_has_failed)
        end
      end

      context "for a guard's group has the :halt_on_fail option == false" do
        before(:each) { @g.stub!(:group) { :bar }; @g.stub!(:failing) { throw :task_has_failed } }

        it "catches :task_has_failed" do
          expect { subject.run_supervised_task(@g, :failing) }.to_not throw_symbol(:task_has_failed)
        end
      end
    end

    context "with a task that raises an exception" do
      before(:each) { @g.stub!(:group) { :foo }; @g.stub!(:failing) { raise "I break your system" } }

      it "fires the Guard" do
        lambda { subject.run_supervised_task(@g, :failing) }.should change(subject.guards, :size).by(-1)
        subject.guards.should_not include(@g)
      end

      it "returns the exception" do
        failing_result = ::Guard.run_supervised_task(@g, :failing)
        failing_result.should be_kind_of(Exception)
        failing_result.message.should == 'I break your system'
      end
    end
  end

  describe '.guard_symbol' do
    let(:guard) { mock(Guard::Guard).as_null_object }

    it 'returns :task_has_failed when the group is missing' do
      subject.guard_symbol(guard).should eql :task_has_failed
    end

    context 'for a group with :halt_on_fail' do
      let(:group) { mock(Guard::Group) }

      before do
        guard.stub(:group).and_return :foo
        group.stub(:options).and_return({ :halt_on_fail => true })
      end

      it 'returns :no_catch' do
        subject.should_receive(:groups).with(:foo).and_return group
        subject.guard_symbol(guard).should eql :no_catch
      end
    end

    context 'for a group without :halt_on_fail' do
      let(:group) { mock(Guard::Group) }

      before do
        guard.stub(:group).and_return :foo
        group.stub(:options).and_return({ :halt_on_fail => false })
      end

      it 'returns :task_has_failed' do
        subject.should_receive(:groups).with(:foo).and_return group
        subject.guard_symbol(guard).should eql :task_has_failed
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
      Kernel.send(:remove_method, :system, :'`')
      Kernel.send(:define_method, :system, @original_system.to_proc)
      Kernel.send(:define_method, :"`", @original_command.to_proc)
    end

    it "outputs Kernel.#system method parameters" do
      ::Guard.setup(:verbose => true)
      ::Guard::UI.should_receive(:debug).with("Command execution: exit 0")
      system("exit", "0").should be_false
    end

    it "outputs Kernel.#` method parameters" do
      ::Guard.setup(:verbose => true)
      ::Guard::UI.should_receive(:debug).twice.with("Command execution: echo test")
      `echo test`.should eql "test\n"
      %x{echo test}.should eql "test\n"
    end

  end

end
