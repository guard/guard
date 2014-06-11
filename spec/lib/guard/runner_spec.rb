require 'spec_helper'
require 'guard/plugin'

describe Guard::Runner do

  before do
    # These are implemented, because otherwise stubbing _scoped_plugins is too
    # much work
    module Guard
      class Foo < Guard::Plugin
        def my_task; fail "#{__method__} is not stubbed"; end

        def my_hard_task; fail "#{__method__} is not stubbed"; end

        def regular_without_arg; fail "#{__method__} is not stubbed"; end

        def regular_with_arg(_arg); fail "#{__method__} is not stubbed"; end

        def failing; fail "#{__method__} is not stubbed"; end

        def run_on_modifications; fail "#{__method__} is not stubbed"; end

        def run_on_change; fail "#{__method__} is not stubbed"; end

        def run_on_additions; fail "#{__method__} is not stubbed"; end

        def run_on_removals; fail "#{__method__} is not stubbed"; end

        def run_on_deletion; fail "#{__method__} is not stubbed"; end
      end

      class Bar < Guard::Plugin
        def my_task; fail "#{__method__} is not stubbed"; end

        def my_hard_task; fail "#{__method__} is not stubbed"; end
      end

      class Baz < Guard::Plugin
        def my_task; fail "#{__method__} is not stubbed"; end
      end
    end

    allow(Guard::Notifier).to receive(:turn_on) {}
    allow(Listen).to receive(:to).with(Dir.pwd, {})

    guard = ::Guard.setup

    @backend_group  = guard.add_group(:backend)
    @frontend_group = guard.add_group(:frontend)
    @foo_guard      = guard.add_plugin(:foo,  group: :backend)
    @bar_guard      = guard.add_plugin(:bar,  group: :frontend)
    @baz_guard      = guard.add_plugin(:baz,  group: :frontend)

    allow(@foo_guard).to receive(:my_task)
    allow(@bar_guard).to receive(:my_task)
    allow(@baz_guard).to receive(:my_task)

    allow(@foo_guard).to receive(:my_hard_task)
    allow(@bar_guard).to receive(:my_hard_task)

  end

  after do
    Guard.module_eval do
      %w(Foo Bar Baz).each { |klass| remove_const(klass) }
    end
  end

  describe '#run' do
    it 'executes supervised task on all registered plugins implementing it' do
      [@foo_guard, @bar_guard].each do |plugin|
        expect(subject).to receive(:run_supervised_task).
          with(plugin, :my_hard_task)

      end
      subject.run(:my_hard_task)
    end

    it 'marks an action as unit of work' do
      expect(Lumberjack).to receive(:unit_of_work)
      subject.run(:my_task)
    end

    context 'with a failing task' do
      before do
        allow(subject).to receive(:run_supervised_task) do
          throw :task_has_failed
        end
      end

      it 'catches the thrown symbol' do
        expect do
          subject.run(:failing)
        end.to_not throw_symbol(:task_has_failed)
      end
    end

    context 'with a plugin as scope' do
      context 'passed as a symbol' do
        let(:scope) { { plugin: :bar } }

        it 'executes the supervised task on the specified plugin only' do
          expect(subject).to receive(:run_supervised_task).
            with(@bar_guard, :my_task)

          expect(subject).to_not receive(:run_supervised_task).
            with(@foo_guard, :my_task)

          expect(subject).to_not receive(:run_supervised_task).
            with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end

      context 'passed as a Guard::Plugin object' do
        let(:scope) { { plugin: @bar_guard } }

        it 'executes the supervised task on the specified plugin only' do
          expect(subject).to receive(:run_supervised_task).
            with(@bar_guard, :my_task)

          expect(subject).to_not receive(:run_supervised_task).
            with(@foo_guard, :my_task)

          expect(subject).to_not receive(:run_supervised_task).
            with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end
    end

    context 'with an array of plugins as scope' do
      context 'passed as a symbol' do
        let(:scope) { { plugins: [:foo, :bar] } }

        it 'executes the supervised task on the specified plugins only' do
          allow(@bar_guard).to receive(:my_task)
          expect(subject).to receive(:run_supervised_task).
            with(@foo_guard, :my_task)

          expect(subject).to receive(:run_supervised_task).
            with(@bar_guard, :my_task)

          expect(subject).to_not receive(:run_supervised_task).
            with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end

      context 'passed as a Guard::Plugin objects' do
        let(:scope) { { plugins: [@foo_guard, @bar_guard] } }

        it 'executes the supervised task on the specified plugins only' do
          expect(subject).to receive(:run_supervised_task).
            with(@foo_guard, :my_task)

          expect(subject).to receive(:run_supervised_task).
            with(@bar_guard, :my_task)

          expect(subject).to_not receive(:run_supervised_task).
            with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end
    end

    context 'with a group as scope' do
      context 'passed as a symbol' do
        let(:scope) { { group: :frontend } }

        it 'executes the supervised task on the specified plugin only' do
          expect(subject).to receive(:run_supervised_task).
            with(@bar_guard, :my_task)

          expect(subject).to receive(:run_supervised_task).
            with(@baz_guard, :my_task)

          expect(subject).to_not receive(:run_supervised_task).
            with(@foo_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end

      context 'passed as a Guard::Group object' do
        let(:scope) { { group: @frontend_group } }

        it 'executes the supervised task on the specified plugin only' do
          expect(subject).to receive(:run_supervised_task).
            with(@bar_guard, :my_task)

          expect(subject).to receive(:run_supervised_task).
            with(@baz_guard, :my_task)

          expect(subject).to_not receive(:run_supervised_task).
            with(@foo_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end
    end

    context 'with an array of plugins as scope' do
      context 'passed as a symbol' do
        let(:scope) { { groups: [:frontend, :backend] } }

        it 'executes the supervised task on the specified plugins only' do
          expect(subject).to receive(:run_supervised_task).
            with(@foo_guard, :my_task)

          expect(subject).to receive(:run_supervised_task).
            with(@bar_guard, :my_task)

          expect(subject).to receive(:run_supervised_task).
            with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end

      context 'passed as a Guard::Group objects' do
        let(:scope) { { groups: [@frontend_group, @backend_group] } }

        it 'executes the supervised task on the specified plugins only' do
          expect(subject).to receive(:run_supervised_task).
            with(@foo_guard, :my_task)

          expect(subject).to receive(:run_supervised_task).
            with(@bar_guard, :my_task)

          expect(subject).to receive(:run_supervised_task).
            with(@baz_guard, :my_task)

          subject.run(:my_task, scope)
        end
      end
    end
  end

  describe '#run_on_changes' do
    let(:changes) { [[], [], []] }
    let(:watcher_module) { ::Guard::Watcher }

    before do
      allow(subject).to receive(:_scoped_plugins).and_yield(@foo_guard)
      allow(subject).to receive(:_clearable?) { false }
      allow(watcher_module).to receive(:match_files) { [] }
    end

    it 'always calls UI.clearable' do
      expect(Guard::UI).to receive(:clearable)
      subject.run_on_changes(*changes)
    end

    context 'when clearable' do
      before { allow(subject).to receive(:_clearable?) { true } }

      it 'clear UI' do
        expect(Guard::UI).to receive(:clear)
        subject.run_on_changes(*changes)
      end
    end

    context 'with no changes' do
      it 'does not run any task' do
        %w(
          run_on_modifications
          run_on_change
          run_on_additions
          run_on_removals
          run_on_deletion).each do |task|
          expect(@foo_guard).to_not receive(task.to_sym)
        end
        subject.run_on_changes(*changes)
      end
    end

    context 'with modified files but modified paths is empty' do
      let(:modified) { %w(file.txt image.png) }

      before do
        changes[0] = modified
        expect(watcher_module).to receive(:match_files).once.
          with(@foo_guard, modified).and_return([])

      end

      it 'does not call run_first_task_found' do
        expect(subject).to_not receive(:_run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with modified paths' do
      let(:modified) { %w(file.txt image.png) }

      before do
        changes[0] = modified
        expect(watcher_module).to receive(:match_files).
          with(@foo_guard, modified).and_return(modified)

      end

      it 'executes the :run_first_task_found task' do
        expect(subject).to receive(:_run_first_task_found).
          with(
            @foo_guard,
            [:run_on_modifications, :run_on_changes, :run_on_change], modified)

        subject.run_on_changes(*changes)
      end
    end

    context 'with added files but added paths is empty' do
      let(:added) { %w(file.txt image.png) }

      before do
        changes[0] = added
        expect(watcher_module).to receive(:match_files).once.
          with(@foo_guard, added).and_return([])

      end

      it 'does not call run_first_task_found' do
        expect(subject).to_not receive(:_run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with added paths' do
      let(:added) { %w(file.txt image.png) }

      before do
        changes[1] = added
        expect(watcher_module).to receive(:match_files).
          with(@foo_guard, added).and_return(added)

      end

      it 'executes the :run_on_additions task' do
        expect(subject).to receive(:_run_first_task_found).
          with(
            @foo_guard,
            [:run_on_additions, :run_on_changes, :run_on_change],
            added)

        subject.run_on_changes(*changes)
      end
    end

    context 'with removed files but removed paths is empty' do
      let(:removed) { %w(file.txt image.png) }

      before do
        changes[0] = removed
        expect(watcher_module).to receive(:match_files).once.
          with(@foo_guard, removed) { [] }

      end

      it 'does not call run_first_task_found' do
        expect(subject).to_not receive(:_run_first_task_found)
        subject.run_on_changes(*changes)
      end
    end

    context 'with removed paths' do
      let(:removed) { %w(file.txt image.png) }

      before do
        changes[2] = removed
        expect(watcher_module).to receive(:match_files).
          with(@foo_guard, removed) { removed }

      end

      it 'executes the :run_on_removals task' do
        expect(subject).to receive(:_run_first_task_found).
          with(
            @foo_guard,
            [:run_on_removals, :run_on_changes, :run_on_deletion],
            removed)

        subject.run_on_changes(*changes)
      end
    end
  end

  describe '#run_supervised_task' do
    it 'executes the task on the passed guard' do
      expect(@foo_guard).to receive(:my_task)
      subject.run_supervised_task(@foo_guard, :my_task)
    end

    context 'with a task that succeeds' do
      context 'without any arguments' do
        before do
          allow(@foo_guard).to receive(:regular_without_arg) { true }
        end

        it 'does not remove the Guard' do
          expect do
            subject.run_supervised_task(@foo_guard, :regular_without_arg)
          end.to_not change(::Guard.plugins, :size)
        end

        it 'returns the result of the task' do
          result = subject.run_supervised_task(@foo_guard, :regular_without_arg)
          expect(result).to be_truthy
        end

        it 'calls :begin and :end hooks' do
          expect(@foo_guard).to receive(:hook).
            with('regular_without_arg_begin')

          expect(@foo_guard).to receive(:hook).
            with('regular_without_arg_end', true)

          subject.run_supervised_task(@foo_guard, :regular_without_arg)
        end

        it 'passes the result of the supervised method to the :end hook'  do
          expect(@foo_guard).to receive(:hook).
            with('regular_without_arg_begin')

          expect(@foo_guard).to receive(:hook).
            with('regular_without_arg_end', true)

          subject.run_supervised_task(@foo_guard, :regular_without_arg)
        end
      end

      context 'with arguments' do
        before do
          allow(@foo_guard).to receive(:regular_with_arg).
            with('given_path') { "I'm a success" }
        end

        it 'does not remove the Guard' do
          expect do
            subject.run_supervised_task(
              @foo_guard,
              :regular_with_arg,
              'given_path')

          end.to_not change(::Guard.plugins, :size)
        end

        it 'returns the result of the task' do
          result = subject.run_supervised_task(
            @foo_guard,
            :regular_with_arg,
            'given_path')

          expect(result).to eq "I'm a success"
        end

        it 'calls the default begin hook but not the default end hook' do
          expect(@foo_guard).to receive(:hook).with('failing_begin')
          expect(@foo_guard).to_not receive(:hook).with('failing_end')
          subject.run_supervised_task(@foo_guard, :failing)
        end
      end
    end

    context 'with a task that throws :task_has_failed' do
      before do
        allow(@foo_guard).to receive(:failing) { throw :task_has_failed }
      end

      context 'in a group' do
        context 'with halt_on_fail: true' do
          before { @backend_group.options[:halt_on_fail] = true }

          it 'throws :task_has_failed' do
            expect do
              subject.run_supervised_task(@foo_guard, :failing)
            end.to throw_symbol(:task_has_failed)
          end
        end

        context 'with halt_on_fail: false' do
          before { @backend_group.options[:halt_on_fail] = false }

          it 'catches :task_has_failed' do
            expect do
              subject.run_supervised_task(@foo_guard, :failing)
            end.to_not throw_symbol(:task_has_failed)
          end
        end
      end
    end

    context 'with a task that raises an exception' do
      before do
        allow(@foo_guard).to receive(:failing) { fail 'I break your system' }
      end

      it 'removes the Guard' do
        expect do
          subject.run_supervised_task(@foo_guard, :failing)
        end.to change(::Guard.plugins, :size).by(-1)

        expect(::Guard.plugins).not_to include(@foo_guard)
      end

      it 'display an error to the user' do
        expect(::Guard::UI).to receive :error
        expect(::Guard::UI).to receive :info

        subject.run_supervised_task(@foo_guard, :failing)
      end

      it 'returns the exception' do
        failing_result = subject.run_supervised_task(@foo_guard, :failing)
        expect(failing_result).to be_kind_of(Exception)
        expect(failing_result.message).to eq 'I break your system'
      end
    end
  end

  describe '.stopping_symbol_for' do
    let(:guard_plugin) { instance_double(Guard::Plugin).as_null_object }

    context 'for a group with :halt_on_fail' do
      before do
        allow(guard_plugin.group).to receive(:options) do
          { halt_on_fail: true }
        end
      end

      it 'returns :no_catch' do
        symbol = described_class.stopping_symbol_for(guard_plugin)
        expect(symbol).to eq :no_catch
      end
    end

    context 'for a group without :halt_on_fail' do
      before do
        allow(guard_plugin.group).to receive(:options) do
          { halt_on_fail: false }
        end
      end

      it 'returns :task_has_failed' do
        symbol = described_class.stopping_symbol_for(guard_plugin)
        expect(symbol).to eq :task_has_failed
      end
    end
  end
end
