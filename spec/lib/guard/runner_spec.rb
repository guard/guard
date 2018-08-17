# frozen_string_literal: true
require 'guard/runner'

require 'guard/plugin'

RSpec.describe Guard::Runner do
  let(:ui_config) { instance_double('Guard::UI::Config') }
  let(:backend_group) do
    instance_double('Guard::Group', options: {}, name: :backend)
  end

  let(:frontend_group) do
    instance_double('Guard::Group', options: {}, name: :frontend)
  end

  let(:foo_plugin) { double('foo', group: backend_group, hook: nil) }
  let(:bar_plugin) { double('bar', group: frontend_group, hook: nil) }
  let(:baz_plugin) { double('baz', group: frontend_group, hook: nil) }

  let(:scope) { instance_double('Guard::Internals::Scope') }
  let(:plugins) { instance_double('Guard::Internals::Plugins') }
  let(:state) { instance_double('Guard::Internals::State') }
  let(:session) { instance_double('Guard::Internals::Session') }

  before do
    allow(session).to receive(:plugins).and_return(plugins)
    allow(state).to receive(:session).and_return(session)
    allow(state).to receive(:scope).and_return(scope)
    allow(Guard).to receive(:state).and_return(state)

    allow(Guard::UI::Config).to receive(:new).and_return(ui_config)
  end

  before do
    Guard::UI.options = nil
  end

  after do
    Guard::UI.reset_logger
    Guard::UI.options = nil
  end

  describe '#run' do
    before do
      allow(scope).to receive(:grouped_plugins).with({})
        .and_return([[nil, [foo_plugin, bar_plugin, baz_plugin]]])

      allow(ui_config).to receive(:with_progname).and_yield
    end

    it 'executes supervised task on all registered plugins implementing it' do
      [foo_plugin, bar_plugin].each do |plugin|
        expect(plugin).to receive(:my_hard_task)
      end

      subject.run(:my_hard_task)
    end

    it 'marks an action as unit of work' do
      expect(Lumberjack).to receive(:unit_of_work)
      subject.run(:my_task)
    end

    context 'with interrupted task' do
      before do
        allow(foo_plugin).to receive(:failing).and_raise(Interrupt)
        # allow(Guard).to receive(:plugins).and_return([foo_plugin])
      end

      it 'catches the thrown symbol' do
        expect { subject.run(:failing) }.to_not throw_symbol(:task_has_failed)
      end
    end

    context 'with a scope' do
      let(:scope_hash) { { plugin: :bar } }

      it 'executes the supervised task on the specified plugin only' do
        expect(scope).to receive(:grouped_plugins).with(scope_hash)
          .and_return([[nil, [bar_plugin]]])

        expect(bar_plugin).to receive(:my_task)
        expect(foo_plugin).to_not receive(:my_task)
        expect(baz_plugin).to_not receive(:my_task)

        subject.run(:my_task, scope_hash)
      end
    end

    context 'with no scope' do
      let(:scope_hash) { nil }

      it 'executes the supervised task using current scope' do
        expect(bar_plugin).to receive(:my_task)
        expect(foo_plugin).to receive(:my_task)
        expect(baz_plugin).to receive(:my_task)

        subject.run(:my_task, scope_hash)
      end
    end
  end

  describe '#run_on_changes' do
    let(:changes) { [[], [], []] }
    let(:watcher_module) { Guard::Watcher }

    before do
      allow(watcher_module).to receive(:match_files) { [] }
      allow(Guard::UI).to receive(:clear)

      allow(foo_plugin).to receive(:regular_without_arg) { fail 'not stubbed' }
      allow(foo_plugin).to receive(:regular_with_arg) { fail 'not stubbed' }
      allow(foo_plugin).to receive(:failing) { fail 'not stubbed' }

      # TODO: runner shouldn't have to know about these
      allow(foo_plugin).to receive(:run_on_modifications) { fail 'not stubbed' }
      allow(foo_plugin).to receive(:run_on_change) { fail 'not stubbed' }
      allow(foo_plugin).to receive(:run_on_additions) { fail 'not stubbed' }
      allow(foo_plugin).to receive(:run_on_removals) { fail 'not stubbed' }
      allow(foo_plugin).to receive(:run_on_deletion) { fail 'not stubbed' }

      allow(foo_plugin).to receive(:my_task)
      allow(bar_plugin).to receive(:my_task)
      allow(baz_plugin).to receive(:my_task)

      allow(foo_plugin).to receive(:name).and_return('Foo')

      allow(scope).to receive(:grouped_plugins) do |args|
        fail "stub me (#{args.inspect})!"
      end

      # disable reevaluator
      allow(scope).to receive(:grouped_plugins).with(group: :common)
        .and_return([[nil, []]])

      # foo in default group
      allow(scope).to receive(:grouped_plugins).with(group: :default)
        .and_return([[nil, [foo_plugin]]])

      allow(scope).to receive(:grouped_plugins).with(no_args)
        .and_return([[nil, [foo_plugin]]])

      allow(ui_config).to receive(:with_progname).and_yield
    end

    it 'always calls UI.clearable' do
      expect(Guard::UI).to receive(:clearable)
      expect(scope).to receive(:grouped_plugins).with(no_args)
        .and_return([[nil, [foo_plugin]]])

      subject.run_on_changes(*changes)
    end

    context 'when clearable' do
      it 'clear UI' do
        expect(Guard::UI).to receive(:clear)
        expect(scope).to receive(:grouped_plugins).with(no_args)
          .and_return([[nil, [foo_plugin]]])
        subject.run_on_changes(*changes)
      end
    end

    context 'with no changes' do
      it 'does not run any task' do
        %w[
          run_on_modifications
          run_on_change
          run_on_additions
          run_on_removals
          run_on_deletion
        ].each do |task|
          expect(foo_plugin).to_not receive(task.to_sym)
        end
        subject.run_on_changes(*changes)
      end
    end

    context 'with modified files but modified paths is empty' do
      let(:modified) { %w[file.txt image.png] }

      before do
        changes[0] = modified
        expect(watcher_module).to receive(:match_files).once
          .with(foo_plugin, modified).and_return([])

        # stub so respond_to? works
      end

      it 'does not call run anything' do
        expect(foo_plugin).to_not receive(:run_on_modifications)
        subject.run_on_changes(*changes)
      end
    end

    context 'with modified paths' do
      let(:modified) { %w[file.txt image.png] }

      before do
        changes[0] = modified
        expect(watcher_module).to receive(:match_files)
          .with(foo_plugin, modified).and_return(modified)
      end

      it 'executes the :run_first_task_found task' do
        expect(foo_plugin).to receive(:run_on_modifications).with(modified) {}
        subject.run_on_changes(*changes)
      end
    end

    context 'with added files but added paths is empty' do
      let(:added) { %w[file.txt image.png] }

      before do
        changes[0] = added
        expect(watcher_module).to receive(:match_files).once
          .with(foo_plugin, added).and_return([])
      end

      it 'does not call run anything' do
        expect(foo_plugin).to_not receive(:run_on_additions)
        subject.run_on_changes(*changes)
      end
    end

    context 'with added paths' do
      let(:added) { %w[file.txt image.png] }

      before do
        changes[1] = added
        expect(watcher_module).to receive(:match_files)
          .with(foo_plugin, added).and_return(added)
      end

      it 'executes the :run_on_additions task' do
        expect(foo_plugin).to receive(:run_on_additions).with(added) {}
        subject.run_on_changes(*changes)
      end
    end

    context 'with non-matching removed paths' do
      let(:removed) { %w[file.txt image.png] }

      before do
        changes[2] = removed
        expect(watcher_module).to receive(:match_files).once
          .with(foo_plugin, removed) { [] }

        # stub so respond_to? works
        allow(foo_plugin).to receive(:run_on_removals)
      end

      it 'does not call tasks' do
        expect(foo_plugin).to_not receive(:run_on_removals)
        subject.run_on_changes(*changes)
      end
    end

    context 'with matching removed paths' do
      let(:removed) { %w[file.txt image.png] }

      before do
        changes[2] = removed
        expect(watcher_module).to receive(:match_files)
          .with(foo_plugin, removed) { removed }
      end

      it 'executes the :run_on_removals task' do
        expect(foo_plugin).to receive(:run_on_removals).with(removed) {}
        subject.run_on_changes(*changes)
      end
    end
  end

  describe '#_supervise' do
    before do
      allow(ui_config).to receive(:with_progname).and_yield
    end

    it 'executes the task on the passed guard' do
      expect(foo_plugin).to receive(:my_task)
      subject.send(:_supervise, foo_plugin, :my_task)
    end

    context 'with a task that succeeds' do
      context 'without any arguments' do
        before do
          allow(foo_plugin).to receive(:regular_without_arg) { true }
        end

        it 'does not remove the Guard' do
          expect(plugins).to_not receive(:remove)
          subject.send(:_supervise, foo_plugin, :regular_without_arg)
        end

        it 'returns the result of the task' do
          result = subject.send(:_supervise, foo_plugin, :regular_without_arg)
          expect(result).to be_truthy
        end

        it 'calls :begin and :end hooks' do
          expect(foo_plugin).to receive(:hook)
            .with('regular_without_arg_begin')

          expect(foo_plugin).to receive(:hook)
            .with('regular_without_arg_end', true)

          subject.send(:_supervise, foo_plugin, :regular_without_arg)
        end

        it 'passes the result of the supervised method to the :end hook' do
          expect(foo_plugin).to receive(:hook)
            .with('regular_without_arg_begin')

          expect(foo_plugin).to receive(:hook)
            .with('regular_without_arg_end', true)

          subject.send(:_supervise, foo_plugin, :regular_without_arg)
        end
      end

      context 'with arguments' do
        before do
          allow(foo_plugin).to receive(:regular_with_arg)
            .with('given_path') { "I'm a success" }
        end

        it 'does not remove the Guard' do
          expect(plugins).to_not receive(:remove)
          subject.send(
            :_supervise,
            foo_plugin,
            :regular_with_arg,
            'given_path'
          )
        end

        it 'returns the result of the task' do
          result = subject.send(
            :_supervise,
            foo_plugin,
            :regular_with_arg,
            'given_path'
          )

          expect(result).to eq "I'm a success"
        end
      end
    end

    context 'with a task that throws :task_has_failed' do
      before do
        allow(foo_plugin).to receive(:failing) { throw :task_has_failed }
      end

      context 'in a group' do
        context 'with halt_on_fail: true' do
          before { backend_group.options[:halt_on_fail] = true }

          it 'throws :task_has_failed' do
            expect do
              subject.send(:_supervise, foo_plugin, :failing)
            end.to throw_symbol(:task_has_failed)
          end
        end

        context 'with halt_on_fail: false' do
          before { backend_group.options[:halt_on_fail] = false }

          it 'catches :task_has_failed' do
            expect do
              subject.send(:_supervise, foo_plugin, :failing)
            end.to_not throw_symbol(:task_has_failed)
          end
        end
      end
    end

    context 'with a task that raises an exception' do
      before do
        allow(foo_plugin).to receive(:failing) { fail 'I break your system' }
        allow(plugins).to receive(:remove).with(foo_plugin)
      end

      it 'removes the Guard' do
        expect(plugins).to receive(:remove).with(foo_plugin) {}
        subject.send(:_supervise, foo_plugin, :failing)
      end

      it 'display an error to the user' do
        expect(::Guard::UI).to receive :error
        expect(::Guard::UI).to receive :info

        subject.send(:_supervise, foo_plugin, :failing)
      end

      it 'returns the exception' do
        failing_result = subject.send(:_supervise, foo_plugin, :failing)
        expect(failing_result).to be_kind_of(Exception)
        expect(failing_result.message).to eq 'I break your system'
      end

      it 'calls the default begin hook but not the default end hook' do
        expect(foo_plugin).to receive(:hook).with('failing_begin')
        expect(foo_plugin).to_not receive(:hook).with('failing_end')
        subject.send(:_supervise, foo_plugin, :failing)
      end
    end
  end

  describe '.stopping_symbol_for' do
    let(:guard_plugin) { instance_double('Guard::Plugin') }
    let(:group) { instance_double('Guard::Group', title: 'Foo') }

    before do
      allow(guard_plugin).to receive(:group).and_return(group)
    end

    context 'for a group with :halt_on_fail' do
      before do
        allow(group).to receive(:options).and_return(halt_on_fail: true)
      end

      it 'returns :no_catch' do
        symbol = described_class.stopping_symbol_for(guard_plugin)
        expect(symbol).to eq :no_catch
      end
    end

    context 'for a group without :halt_on_fail' do
      before do
        allow(group).to receive(:options).and_return(halt_on_fail: false)
      end

      it 'returns :task_has_failed' do
        symbol = described_class.stopping_symbol_for(guard_plugin)
        expect(symbol).to eq :task_has_failed
      end
    end
  end
end
