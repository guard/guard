require 'spec_helper'

describe Guard::Runner do
  before(:all) do
    # Define two guard implementations
    class ::Guard::Foo < ::Guard::Guard; end
    class ::Guard::Bar1 < ::Guard::Guard; end
    class ::Guard::Bar2 < ::Guard::Guard; end
  end

  let(:guard_module) { ::Guard }
  let(:ui_module)    { guard_module::UI }
  let!(:guard_singleton) { guard_module.setup }

  # One guard in one group
  let!(:foo_group)  { guard_singleton.add_group(:foo) }
  let!(:foo_guard)  { guard_singleton.add_guard(:foo, [], [], :group => :foo) }

  # Two guards in one group
  let!(:bar_group)  { guard_singleton.add_group(:bar) }
  let!(:bar1_guard) { guard_singleton.add_guard(:bar1, [], [], :group => :bar) }
  let!(:bar2_guard) { guard_singleton.add_guard(:bar2, [], [], :group => :bar) }

  before do
    # Stub the groups to avoid using the real ones from Guardfile (ex.: Guard::Rspec)
    guard_module.stub(:groups) { [foo_group, bar_group] }
  end

  after(:all) do
    # Be nice and don't clutter the namespace
    ::Guard.instance_eval do
      remove_const(:Foo)
      remove_const(:Bar1)
      remove_const(:Bar2)
    end
  end

  describe '#deprecation_warning' do
    before { guard_module.stub(:guards) { [foo_guard] } }

    context 'when neither run_on_change nor run_on_deletion is implemented in a guard' do
      it 'does not display a deprecation warning to the user' do
        ui_module.should_not_receive(:deprecation)
        subject.deprecation_warning
      end
    end

    context 'when run_on_change is implemented in a guard' do
      before { foo_guard.stub(:run_on_change) }

      it 'displays a deprecation warning to the user' do
        ui_module.should_receive(:deprecation).with(
          described_class::RUN_ON_CHANGE_DEPRECATION % foo_guard.class.name
        )
        subject.deprecation_warning
      end
    end

    context 'when run_on_deletion is implemented in a guard' do
      before { foo_guard.stub(:run_on_deletion) }

      it 'displays a deprecation warning to the user' do
        ui_module.should_receive(:deprecation).with(
          described_class::RUN_ON_DELETION_DEPRECATION % foo_guard.class.name
        )
        subject.deprecation_warning
      end
    end
  end

  describe '#run' do
    let(:scopes) { { :group => foo_group } }

    it 'executes a supervised task on all registered guards' do
      [foo_guard, bar1_guard, bar2_guard].each do |g|
        subject.should_receive(:run_supervised_task).with(g, :my_task)
      end
      subject.run(:my_task)
    end

    context 'with a failing task' do
      before { subject.stub(:run_supervised_task) { throw :task_has_failed } }

      it 'catches the thrown symbol' do
        expect {
          subject.run(:failing)
        }.to_not throw_symbol(:task_has_failed)
      end
    end

    context 'within the scope of a specified guard' do
      let(:scopes) { { :guard => bar1_guard } }

      it 'executes the supervised task on the specified guard only' do
        subject.should_receive(:run_supervised_task).with(bar1_guard, :my_task)

        subject.should_not_receive(:run_supervised_task).with(foo_guard, :my_task)
        subject.should_not_receive(:run_supervised_task).with(bar2_guard, :my_task)

        subject.run(:my_task, scopes)
      end
    end

    context 'within the scope of a specified group' do
      let(:scopes) { { :group => foo_group } }

      it 'executes the task on each guard in the specified group only' do
        subject.should_receive(:run_supervised_task).with(foo_guard, :my_task)

        subject.should_not_receive(:run_supervised_task).with(bar1_guard, :my_task)
        subject.should_not_receive(:run_supervised_task).with(bar2_guard, :my_task)

        subject.run(:my_task, scopes)
      end
    end
  end

  describe '#run_on_changes' do
    let(:changes) { [ [], [], [] ] }
    let(:watcher_module) { ::Guard::Watcher }

    before {
      subject.stub(:scoped_guards).and_yield(foo_guard)
      subject.stub(:clearable?) { false }
      watcher_module.stub(:match_files) { [] }
    }

    context 'when clearable' do
      before { subject.stub(:clearable?) { true } }

      it "clear UI" do
        Guard::UI.should_receive(:clear)
        subject.run_on_changes(*changes)
      end
    end

    context 'with no changes' do
      it 'does not run any task' do
        %w[run_on_modifications run_on_change run_on_additions run_on_removals run_on_deletion].each do |task|
          foo_guard.should_not_receive(task.to_sym)
        end
        subject.run_on_changes(*changes)
      end
    end

    context "with modified files but modified paths is empty" do
      let(:modified) { %w[file.txt image.png] }

      before do
        changes[0] = modified
        watcher_module.should_receive(:match_files).once.with(foo_guard, modified).and_return([])
      end

      it 'does not call run_first_task_found' do
        subject.should_not_receive(:run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with modified paths' do
      let(:modified) { %w[file.txt image.png] }

      before do
        changes[0] = modified
        watcher_module.should_receive(:match_files).with(foo_guard, modified).and_return(modified)
      end

      it 'executes the :run_first_task_found task' do
        subject.should_receive(:run_first_task_found).with(foo_guard, [:run_on_modifications, :run_on_changes, :run_on_change], modified)
        subject.run_on_changes(*changes)
      end
    end

    context "with added files but added paths is empty" do
      let(:added) { %w[file.txt image.png] }

      before do
        changes[0] = added
        watcher_module.should_receive(:match_files).once.with(foo_guard, added).and_return([])
      end

      it 'does not call run_first_task_found' do
        subject.should_not_receive(:run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with added paths' do
      let(:added) { %w[file.txt image.png] }

      before do
        changes[1] = added
        watcher_module.should_receive(:match_files).with(foo_guard, added).and_return(added)
      end

      it 'executes the :run_on_additions task' do
        subject.should_receive(:run_first_task_found).with(foo_guard, [:run_on_additions, :run_on_changes, :run_on_change], added)
        subject.run_on_changes(*changes)
      end
    end

    context "with removed files but removed paths is empty" do
      let(:removed) { %w[file.txt image.png] }

      before do
        changes[0] = removed
        watcher_module.should_receive(:match_files).once.with(foo_guard, removed).and_return([])
      end

      it 'does not call run_first_task_found' do
        subject.should_not_receive(:run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with removed paths' do
      let(:removed) { %w[file.txt image.png] }

      before do
        changes[2] = removed
        watcher_module.should_receive(:match_files).with(foo_guard, removed).and_return(removed)
      end

      it 'executes the :run_on_removals task' do
        subject.should_receive(:run_first_task_found).with(foo_guard, [:run_on_removals, :run_on_changes, :run_on_deletion], removed)
        subject.run_on_changes(*changes)
      end
    end
  end

  describe '#run_supervised_task' do
    before { guard_module.unstub(:groups) }

    it 'executes the task on the passed guard' do
      foo_guard.should_receive(:my_task)
      subject.run_supervised_task(foo_guard, :my_task)
    end

    it 'runs the task within a preserved state' do
      guard_module.should_receive(:within_preserved_state)
      subject.run_supervised_task(foo_guard, :my_task)
    end

    context 'with a task that succeeds' do
      context 'without any arguments' do
        before do
          foo_guard.stub(:regular_without_arg) { true }
        end

        it 'does not remove the Guard' do
          expect {
            subject.run_supervised_task(foo_guard, :regular_without_arg)
          }.to_not change(guard_singleton.guards, :size)
        end

        it 'returns the result of the task' do
          subject.run_supervised_task(foo_guard, :regular_without_arg).should be_true
        end

        it 'passes the args to the :begin hook' do
          foo_guard.should_receive(:hook).with('regular_without_arg_begin', 'given_path')
          subject.run_supervised_task(foo_guard, :regular_without_arg, 'given_path')
        end

        it 'passes the result of the supervised method to the :end hook'  do
          foo_guard.should_receive(:hook).with('regular_without_arg_begin', 'given_path')
          foo_guard.should_receive(:hook).with('regular_without_arg_end', true)
          subject.run_supervised_task(foo_guard, :regular_without_arg, 'given_path')
        end
      end

      context 'with arguments' do
        before do
          foo_guard.stub(:regular_with_arg).with('given_path') { "I'm a success" }
        end

        it 'does not remove the Guard' do
          expect {
            subject.run_supervised_task(foo_guard, :regular_with_arg, 'given_path')
          }.to_not change(guard_module.guards, :size)
        end

        it 'returns the result of the task' do
          subject.run_supervised_task(foo_guard, :regular_with_arg, "given_path").should == "I'm a success"
        end

        it 'calls the default begin hook but not the default end hook' do
          foo_guard.should_receive(:hook).with('failing_begin')
          foo_guard.should_not_receive(:hook).with('failing_end')
          subject.run_supervised_task(foo_guard, :failing)
        end
      end
    end

    context 'with a task that throws :task_has_failed' do
      before { foo_guard.stub(:failing) { throw :task_has_failed } }

      context 'for a guard in group that has the :halt_on_fail option set to true' do
        before { foo_group.options[:halt_on_fail] = true }

        it 'throws :task_has_failed' do
          expect {
            subject.run_supervised_task(foo_guard, :failing)
          }.to throw_symbol(:task_has_failed)
        end
      end

      context 'for a guard in a group that has the :halt_on_fail option set to false' do
        before { foo_group.options[:halt_on_fail] = false }

        it 'catches :task_has_failed' do
          expect {
            subject.run_supervised_task(foo_guard, :failing)
          }.to_not throw_symbol(:task_has_failed)
        end
      end
    end

    context 'with a task that raises an exception' do
      before { foo_guard.stub(:failing) { raise 'I break your system' } }

      it 'removes the Guard' do
        expect {
          subject.run_supervised_task(foo_guard, :failing)
        }.to change(guard_module.guards, :size).by(-1)

        guard_module.guards.should_not include(foo_guard)
      end

      it 'display an error to the user' do
        ui_module.should_receive :error
        ui_module.should_receive :info

        subject.run_supervised_task(foo_guard, :failing)
      end

      it 'returns the exception' do
        failing_result = subject.run_supervised_task(foo_guard, :failing)
        failing_result.should be_kind_of(Exception)
        failing_result.message.should == 'I break your system'
      end
    end
  end

  describe '.stopping_symbol_for' do
    let(:guard_implmentation) { mock(Guard::Guard).as_null_object }

    it 'returns :task_has_failed when the group is missing' do
      described_class.stopping_symbol_for(guard_implmentation).should == :task_has_failed
    end

    context 'for a group with :halt_on_fail' do
      let(:group) { mock(Guard::Group) }

      before do
        guard_implmentation.stub(:group).and_return :foo
        group.stub(:options).and_return({ :halt_on_fail => true })
      end

      it 'returns :no_catch' do
        guard_module.should_receive(:groups).with(:foo).and_return group
        described_class.stopping_symbol_for(guard_implmentation).should == :no_catch
      end
    end

    context 'for a group without :halt_on_fail' do
      let(:group) { mock(Guard::Group) }

      before do
        guard_implmentation.stub(:group).and_return :foo
        group.stub(:options).and_return({ :halt_on_fail => false })
      end

      it 'returns :task_has_failed' do
        guard_module.should_receive(:groups).with(:foo).and_return group
        described_class.stopping_symbol_for(guard_implmentation).should == :task_has_failed
      end
    end
  end

end
