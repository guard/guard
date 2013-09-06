require 'spec_helper'
require 'guard/plugin'

describe Guard::Runner do

  before do
    guard = ::Guard.setup
    stub_const 'Guard::Foo', Class.new(Guard::Plugin)
    stub_const 'Guard::Bar', Class.new(Guard::Plugin)
    stub_const 'Guard::Baz', Class.new(Guard::Plugin)

    @backend_group  = guard.add_group(:backend)
    @frontend_group = guard.add_group(:frontend)
    @foo_guard      = guard.add_plugin(:foo, { group: :backend })
    @bar_guard      = guard.add_plugin(:bar, { group: :frontend })
    @baz_guard      = guard.add_plugin(:baz, { group: :frontend })

    @foo_guard.stub(:my_task)
    @bar_guard.stub(:my_task)
    @baz_guard.stub(:my_task)

    @foo_guard.stub(:my_hard_task)
    @bar_guard.stub(:my_hard_task)
  end

  describe '#run' do
    it 'executes a supervised task on all registered plugins implementing that task' do
      [@foo_guard, @bar_guard].each do |plugin|
        subject.should_receive(:run_supervised_task).with(plugin, :my_hard_task)
      end
      subject.run(:my_hard_task)
    end

    it 'marks an action as unit of work' do
      Lumberjack.should_receive(:unit_of_work)
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

    context 'with a plugin as scope' do
      context 'passed as a symbol' do
        let(:scope) { { plugin: :bar } }

        it 'executes the supervised task on the specified plugin only' do
          subject.should_receive(:run_supervised_task).with(@bar_guard, :my_task)

          subject.should_not_receive(:run_supervised_task).with(@foo_guard, :my_task)
          subject.should_not_receive(:run_supervised_task).with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end

      context 'passed as a Guard::Plugin object' do
        let(:scope) { { plugin: @bar_guard } }

        it 'executes the supervised task on the specified plugin only' do
          subject.should_receive(:run_supervised_task).with(@bar_guard, :my_task)

          subject.should_not_receive(:run_supervised_task).with(@foo_guard, :my_task)
          subject.should_not_receive(:run_supervised_task).with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end
    end

    context 'with an array of plugins as scope' do
      context 'passed as a symbol' do
        let(:scope) { { plugins: [:foo, :bar] } }

        it 'executes the supervised task on the specified plugins only' do
          @bar_guard.stub(:my_task)
          subject.should_receive(:run_supervised_task).with(@foo_guard, :my_task)
          subject.should_receive(:run_supervised_task).with(@bar_guard, :my_task)

          subject.should_not_receive(:run_supervised_task).with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end

      context 'passed as a Guard::Plugin objects' do
        let(:scope) { { plugins: [@foo_guard, @bar_guard] } }

        it 'executes the supervised task on the specified plugins only' do
          subject.should_receive(:run_supervised_task).with(@foo_guard, :my_task)
          subject.should_receive(:run_supervised_task).with(@bar_guard, :my_task)

          subject.should_not_receive(:run_supervised_task).with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end
    end

    context 'with a group as scope' do
      context 'passed as a symbol' do
        let(:scope) { { group: :frontend } }

        it 'executes the supervised task on the specified plugin only' do
          subject.should_receive(:run_supervised_task).with(@bar_guard, :my_task)
          subject.should_receive(:run_supervised_task).with(@baz_guard, :my_task)

          subject.should_not_receive(:run_supervised_task).with(@foo_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end

      context 'passed as a Guard::Group object' do
        let(:scope) { { group: @frontend_group } }

        it 'executes the supervised task on the specified plugin only' do
          subject.should_receive(:run_supervised_task).with(@bar_guard, :my_task)
          subject.should_receive(:run_supervised_task).with(@baz_guard, :my_task)

          subject.should_not_receive(:run_supervised_task).with(@foo_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end
    end

    context 'with an array of plugins as scope' do
      context 'passed as a symbol' do
        let(:scope) { { groups: [:frontend, :backend] } }

        it 'executes the supervised task on the specified plugins only' do
          subject.should_receive(:run_supervised_task).with(@foo_guard, :my_task)
          subject.should_receive(:run_supervised_task).with(@bar_guard, :my_task)
          subject.should_receive(:run_supervised_task).with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end

      context 'passed as a Guard::Group objects' do
        let(:scope) { { groups: [@frontend_group, @backend_group] } }

        it 'executes the supervised task on the specified plugins only' do
          subject.should_receive(:run_supervised_task).with(@foo_guard, :my_task)
          subject.should_receive(:run_supervised_task).with(@bar_guard, :my_task)
          subject.should_receive(:run_supervised_task).with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end
    end
  end

  describe '#run_on_changes' do
    let(:changes) { [ [], [], [] ] }
    let(:watcher_module) { ::Guard::Watcher }

    before do
      subject.stub(:_scoped_plugins).and_yield(@foo_guard)
      subject.stub(:_clearable?) { false }
      watcher_module.stub(:match_files) { [] }
    end

    it "always calls UI.clearable" do
      Guard::UI.should_receive(:clearable)
      subject.run_on_changes(*changes)
    end

    context 'when clearable' do
      before { subject.stub(:_clearable?) { true } }

      it "clear UI" do
        Guard::UI.should_receive(:clear)
        subject.run_on_changes(*changes)
      end
    end

    context 'with no changes' do
      it 'does not run any task' do
        %w[run_on_modifications run_on_change run_on_additions run_on_removals run_on_deletion].each do |task|
          @foo_guard.should_not_receive(task.to_sym)
        end
        subject.run_on_changes(*changes)
      end
    end

    context "with modified files but modified paths is empty" do
      let(:modified) { %w[file.txt image.png] }

      before do
        changes[0] = modified
        watcher_module.should_receive(:match_files).once.with(@foo_guard, modified).and_return([])
      end

      it 'does not call run_first_task_found' do
        subject.should_not_receive(:_run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with modified paths' do
      let(:modified) { %w[file.txt image.png] }

      before do
        changes[0] = modified
        watcher_module.should_receive(:match_files).with(@foo_guard, modified).and_return(modified)
      end

      it 'executes the :run_first_task_found task' do
        subject.should_receive(:_run_first_task_found).with(@foo_guard, [:run_on_modifications, :run_on_changes, :run_on_change], modified)
        subject.run_on_changes(*changes)
      end
    end

    context "with added files but added paths is empty" do
      let(:added) { %w[file.txt image.png] }

      before do
        changes[0] = added
        watcher_module.should_receive(:match_files).once.with(@foo_guard, added).and_return([])
      end

      it 'does not call run_first_task_found' do
        subject.should_not_receive(:_run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with added paths' do
      let(:added) { %w[file.txt image.png] }

      before do
        changes[1] = added
        watcher_module.should_receive(:match_files).with(@foo_guard, added).and_return(added)
      end

      it 'executes the :run_on_additions task' do
        subject.should_receive(:_run_first_task_found).with(@foo_guard, [:run_on_additions, :run_on_changes, :run_on_change], added)
        subject.run_on_changes(*changes)
      end
    end

    context "with removed files but removed paths is empty" do
      let(:removed) { %w[file.txt image.png] }

      before do
        changes[0] = removed
        watcher_module.should_receive(:match_files).once.with(@foo_guard, removed).and_return([])
      end

      it 'does not call run_first_task_found' do
        subject.should_not_receive(:_run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with removed paths' do
      let(:removed) { %w[file.txt image.png] }

      before do
        changes[2] = removed
        watcher_module.should_receive(:match_files).with(@foo_guard, removed).and_return(removed)
      end

      it 'executes the :run_on_removals task' do
        subject.should_receive(:_run_first_task_found).with(@foo_guard, [:run_on_removals, :run_on_changes, :run_on_deletion], removed)
        subject.run_on_changes(*changes)
      end
    end
  end

  describe '#run_supervised_task' do
    it 'executes the task on the passed guard' do
      @foo_guard.should_receive(:my_task)
      subject.run_supervised_task(@foo_guard, :my_task)
    end

    context 'with a task that succeeds' do
      context 'without any arguments' do
        before do
          @foo_guard.stub(:regular_without_arg) { true }
        end

        it 'does not remove the Guard' do
          expect {
            subject.run_supervised_task(@foo_guard, :regular_without_arg)
          }.to_not change(::Guard.plugins, :size)
        end

        it 'returns the result of the task' do
          subject.run_supervised_task(@foo_guard, :regular_without_arg).should be_true
        end

        it 'passes the args to the :begin hook' do
          @foo_guard.should_receive(:hook).with('regular_without_arg_begin', 'given_path')
          subject.run_supervised_task(@foo_guard, :regular_without_arg, 'given_path')
        end

        it 'passes the result of the supervised method to the :end hook'  do
          @foo_guard.should_receive(:hook).with('regular_without_arg_begin', 'given_path')
          @foo_guard.should_receive(:hook).with('regular_without_arg_end', true)
          subject.run_supervised_task(@foo_guard, :regular_without_arg, 'given_path')
        end
      end

      context 'with arguments' do
        before do
          @foo_guard.stub(:regular_with_arg).with('given_path') { "I'm a success" }
        end

        it 'does not remove the Guard' do
          expect {
            subject.run_supervised_task(@foo_guard, :regular_with_arg, 'given_path')
          }.to_not change(::Guard.plugins, :size)
        end

        it 'returns the result of the task' do
          subject.run_supervised_task(@foo_guard, :regular_with_arg, "given_path").should eq "I'm a success"
        end

        it 'calls the default begin hook but not the default end hook' do
          @foo_guard.should_receive(:hook).with('failing_begin')
          @foo_guard.should_not_receive(:hook).with('failing_end')
          subject.run_supervised_task(@foo_guard, :failing)
        end
      end
    end

    context 'with a task that throws :task_has_failed' do
      before { @foo_guard.stub(:failing) { throw :task_has_failed } }

      context 'for a guard in group that has the :halt_on_fail option set to true' do
        before { @backend_group.options[:halt_on_fail] = true }

        it 'throws :task_has_failed' do
          expect {
            subject.run_supervised_task(@foo_guard, :failing)
          }.to throw_symbol(:task_has_failed)
        end
      end

      context 'for a guard in a group that has the :halt_on_fail option set to false' do
        before { @backend_group.options[:halt_on_fail] = false }

        it 'catches :task_has_failed' do
          expect {
            subject.run_supervised_task(@foo_guard, :failing)
          }.to_not throw_symbol(:task_has_failed)
        end
      end
    end

    context 'with a task that raises an exception' do
      before { @foo_guard.stub(:failing) { raise 'I break your system' } }

      it 'removes the Guard' do
        expect {
          subject.run_supervised_task(@foo_guard, :failing)
        }.to change(::Guard.plugins, :size).by(-1)

        ::Guard.plugins.should_not include(@foo_guard)
      end

      it 'display an error to the user' do
        ::Guard::UI.should_receive :error
        ::Guard::UI.should_receive :info

        subject.run_supervised_task(@foo_guard, :failing)
      end

      it 'returns the exception' do
        failing_result = subject.run_supervised_task(@foo_guard, :failing)
        failing_result.should be_kind_of(Exception)
        failing_result.message.should eq 'I break your system'
      end
    end
  end

  describe '.stopping_symbol_for' do
    let(:guard_plugin) { double(Guard::Plugin).as_null_object }

    context 'for a group with :halt_on_fail' do
      before do
        guard_plugin.group.stub(:options).and_return({ halt_on_fail: true })
      end

      it 'returns :no_catch' do
        described_class.stopping_symbol_for(guard_plugin).should eq :no_catch
      end
    end

    context 'for a group without :halt_on_fail' do
      before do
        guard_plugin.group.stub(:options).and_return({ halt_on_fail: false })
      end

      it 'returns :task_has_failed' do
        described_class.stopping_symbol_for(guard_plugin).should eq :task_has_failed
      end
    end
  end

end
