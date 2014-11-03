require "guard/plugin"

RSpec.describe Guard::Runner do
  let(:interactor) { instance_double(Guard::Interactor) }

  let(:backend_group) do
    instance_double(::Guard::Group, options: {}, name: :backend)
  end

  let(:frontend_group) do
    instance_double(::Guard::Group, options: {}, name: :frontend)
  end

  let(:foo_plugin) { double("foo", group: backend_group, hook: nil) }
  let(:bar_plugin) { double("bar", group: frontend_group, hook: nil) }
  let(:baz_plugin) { double("baz", group: frontend_group, hook: nil) }

  before do
    allow(Guard::Interactor).to receive(:new).and_return(interactor)
    allow(Guard::Notifier).to receive(:turn_on) {}
    allow(Listen).to receive(:to).with(Dir.pwd, {})
  end

  describe "#run" do
    before do
      allow_any_instance_of(Guard::Guardfile::Evaluator).
        to receive(:evaluate_guardfile)

      ::Guard.setup

      # TODO: these should be replaced when new Scop class is implemented
      allow(::Guard).to receive(:groups).with(no_args).
        and_return([backend_group, frontend_group])

      allow(::Guard).to receive(:groups).with(:common).
        and_return([double("group", name: :common)])

      allow(::Guard).to receive(:plugins).with(group: :common).
        and_return([])

      allow(::Guard).to receive(:plugins).with(group: :backend).
        and_return([foo_plugin])

      allow(::Guard).to receive(:plugins).with(group: :frontend).
        and_return([bar_plugin, baz_plugin])
    end

    it "executes supervised task on all registered plugins implementing it" do
      [foo_plugin, bar_plugin].each do |plugin|
        expect(plugin).to receive(:my_hard_task) {}
      end

      subject.run(:my_hard_task)
    end

    it "marks an action as unit of work" do
      expect(Lumberjack).to receive(:unit_of_work)
      subject.run(:my_task)
    end

    context "with interrupted task" do
      before do
        allow(foo_plugin).to receive(:failing).and_raise(Interrupt)
        allow(::Guard).to receive(:plugins).and_return([foo_plugin])
      end

      it "catches the thrown symbol" do
        expect { subject.run(:failing) }.to_not throw_symbol(:task_has_failed)
      end
    end

    context "with a scope" do
      let(:scope_hash) { { plugin: :bar } }

      it "executes the supervised task on the specified plugin only" do
        expect(::Guard).to receive(:plugins).and_return([bar_plugin])

        expect(bar_plugin).to receive(:my_task)
        expect(foo_plugin).to_not receive(:my_task)
        expect(baz_plugin).to_not receive(:my_task)

        subject.run(:my_task, scope_hash)
      end
    end

    context "with no scope" do
      let(:scope_hash) { nil }

      it "executes the supervised task using current scope" do
        # TODO: this should be cleaned up once scopes are reimplemented
        allow(::Guard).to receive(:groups).with(no_args).
          and_return([backend_group, frontend_group])

        allow(::Guard).to receive(:groups).with(:common).
          and_return([double("group", name: :common)])

        allow(::Guard).to receive(:plugins).with(group: :common).
          and_return([])

        allow(::Guard).to receive(:plugins).with(group: :backend).
          and_return([foo_plugin])

        allow(::Guard).to receive(:plugins).with(group: :frontend).
          and_return([bar_plugin, baz_plugin])

        expect(bar_plugin).to receive(:my_task)
        expect(foo_plugin).to receive(:my_task)
        expect(baz_plugin).to receive(:my_task)

        subject.run(:my_task, scope_hash)
      end
    end
  end

  describe "#run_on_changes" do
    let(:changes) { [[], [], []] }
    let(:watcher_module) { ::Guard::Watcher }

    before do
      allow(watcher_module).to receive(:match_files) { [] }
      allow(Guard::UI).to receive(:clear)

      allow(foo_plugin).to receive(:regular_without_arg) { fail "not stubbed" }
      allow(foo_plugin).to receive(:regular_with_arg) { fail "not stubbed" }
      allow(foo_plugin).to receive(:failing) { fail "not stubbed" }

      # TODO: runner shouldn't have to know about these
      allow(foo_plugin).to receive(:run_on_modifications) { fail "not stubbed" }
      allow(foo_plugin).to receive(:run_on_change) { fail "not stubbed" }
      allow(foo_plugin).to receive(:run_on_additions) { fail "not stubbed" }
      allow(foo_plugin).to receive(:run_on_removals) { fail "not stubbed" }
      allow(foo_plugin).to receive(:run_on_deletion) { fail "not stubbed" }

      allow(foo_plugin).to receive(:my_task)
      allow(bar_plugin).to receive(:my_task)
      allow(baz_plugin).to receive(:my_task)

      allow_any_instance_of(Guard::Guardfile::Evaluator).
        to receive(:evaluate_guardfile)

      allow(::Guard).to receive(:plugins).and_return([foo_plugin])
      allow(foo_plugin).to receive(:name).and_return("Foo")
      ::Guard.setup
      allow(::Guard).to receive(:plugins) do |args|
        fail "stub me (#{args.inspect})!"
      end

      # disable reevaluator
      allow(::Guard).to receive(:plugins).with(group: :common).
        and_return([])

      # foo in default group
      allow(::Guard).to receive(:plugins).with(group: :default).
        and_return([foo_plugin])
    end

    after do
      ::Guard.reset_groups
    end

    it "always calls UI.clearable" do
      expect(Guard::UI).to receive(:clearable)

      subject.run_on_changes(*changes)
    end

    context "when clearable" do
      it "clear UI" do
        expect(Guard::UI).to receive(:clear)
        subject.run_on_changes(*changes)
      end
    end

    context "with no changes" do
      it "does not run any task" do
        %w(
          run_on_modifications
          run_on_change
          run_on_additions
          run_on_removals
          run_on_deletion).each do |task|
          expect(foo_plugin).to_not receive(task.to_sym)
        end
        subject.run_on_changes(*changes)
      end
    end

    context "with modified files but modified paths is empty" do
      let(:modified) { %w(file.txt image.png) }

      before do
        changes[0] = modified
        expect(watcher_module).to receive(:match_files).once.
          with(foo_plugin, modified).and_return([])

        # stub so respond_to? works
      end

      it "does not call run anything" do
        expect(foo_plugin).to_not receive(:run_on_modifications)
        subject.run_on_changes(*changes)
      end
    end

    context "with modified paths" do
      let(:modified) { %w(file.txt image.png) }

      before do
        changes[0] = modified
        expect(watcher_module).to receive(:match_files).
          with(foo_plugin, modified).and_return(modified)
      end

      it "executes the :run_first_task_found task" do
        expect(foo_plugin).to receive(:run_on_modifications).with(modified) {}
        subject.run_on_changes(*changes)
      end
    end

    context "with added files but added paths is empty" do
      let(:added) { %w(file.txt image.png) }

      before do
        changes[0] = added
        expect(watcher_module).to receive(:match_files).once.
          with(foo_plugin, added).and_return([])
      end

      it "does not call run anything" do
        expect(foo_plugin).to_not receive(:run_on_additions)
        subject.run_on_changes(*changes)
      end
    end

    context "with added paths" do
      let(:added) { %w(file.txt image.png) }

      before do
        changes[1] = added
        expect(watcher_module).to receive(:match_files).
          with(foo_plugin, added).and_return(added)
      end

      it "executes the :run_on_additions task" do
        expect(foo_plugin).to receive(:run_on_additions).with(added) {}
        subject.run_on_changes(*changes)
      end
    end

    context "with non-matching removed paths" do
      let(:removed) { %w(file.txt image.png) }

      before do
        changes[2] = removed
        expect(watcher_module).to receive(:match_files).once.
          with(foo_plugin, removed) { [] }

        # stub so respond_to? works
        allow(foo_plugin).to receive(:run_on_removals)
      end

      it "does not call tasks" do
        expect(foo_plugin).to_not receive(:run_on_removals)
        subject.run_on_changes(*changes)
      end
    end

    context "with matching removed paths" do
      let(:removed) { %w(file.txt image.png) }

      before do
        changes[2] = removed
        expect(watcher_module).to receive(:match_files).
          with(foo_plugin, removed) { removed }

      end

      it "executes the :run_on_removals task" do
        expect(foo_plugin).to receive(:run_on_removals).with(removed) {}
        subject.run_on_changes(*changes)
      end
    end
  end

  describe "#_supervise" do
    it "executes the task on the passed guard" do
      expect(foo_plugin).to receive(:my_task)
      subject.send(:_supervise, foo_plugin, :my_task)
    end

    context "with a task that succeeds" do
      context "without any arguments" do
        before do
          allow(foo_plugin).to receive(:regular_without_arg) { true }
        end

        it "does not remove the Guard" do
          expect do
            subject.send(:_supervise, foo_plugin, :regular_without_arg)
          end.to_not change(::Guard.plugins, :size)
        end

        it "returns the result of the task" do
          result = subject.send(:_supervise, foo_plugin, :regular_without_arg)
          expect(result).to be_truthy
        end

        it "calls :begin and :end hooks" do
          expect(foo_plugin).to receive(:hook).
            with("regular_without_arg_begin")

          expect(foo_plugin).to receive(:hook).
            with("regular_without_arg_end", true)

          subject.send(:_supervise, foo_plugin, :regular_without_arg)
        end

        it "passes the result of the supervised method to the :end hook"  do
          expect(foo_plugin).to receive(:hook).
            with("regular_without_arg_begin")

          expect(foo_plugin).to receive(:hook).
            with("regular_without_arg_end", true)

          subject.send(:_supervise, foo_plugin, :regular_without_arg)
        end
      end

      context "with arguments" do
        before do
          allow(foo_plugin).to receive(:regular_with_arg).
            with("given_path") { "I'm a success" }
        end

        it "does not remove the Guard" do
          expect do
            subject.send(
              :_supervise,
              foo_plugin,
              :regular_with_arg,
              "given_path")

          end.to_not change(::Guard.plugins, :size)
        end

        it "returns the result of the task" do
          result = subject.send(
            :_supervise,
            foo_plugin,
            :regular_with_arg,
            "given_path")

          expect(result).to eq "I'm a success"
        end
      end
    end

    context "with a task that throws :task_has_failed" do
      before do
        allow(foo_plugin).to receive(:failing) { throw :task_has_failed }
      end

      context "in a group" do
        context "with halt_on_fail: true" do
          before { backend_group.options[:halt_on_fail] = true }

          it "throws :task_has_failed" do
            expect do
              subject.send(:_supervise, foo_plugin, :failing)
            end.to throw_symbol(:task_has_failed)
          end
        end

        context "with halt_on_fail: false" do
          before { backend_group.options[:halt_on_fail] = false }

          it "catches :task_has_failed" do
            expect do
              subject.send(:_supervise, foo_plugin, :failing)
            end.to_not throw_symbol(:task_has_failed)
          end
        end
      end
    end

    context "with a task that raises an exception" do
      before do
        allow(foo_plugin).to receive(:failing) { fail "I break your system" }
        allow(::Guard).to receive(:remove_plugin).with(foo_plugin)
      end

      it "removes the Guard" do
        expect(::Guard).to receive(:remove_plugin).with(foo_plugin) {}
        subject.send(:_supervise, foo_plugin, :failing)
      end

      it "display an error to the user" do
        expect(::Guard::UI).to receive :error
        expect(::Guard::UI).to receive :info

        subject.send(:_supervise, foo_plugin, :failing)
      end

      it "returns the exception" do
        failing_result = subject.send(:_supervise, foo_plugin, :failing)
        expect(failing_result).to be_kind_of(Exception)
        expect(failing_result.message).to eq "I break your system"
      end

      it "calls the default begin hook but not the default end hook" do
        expect(foo_plugin).to receive(:hook).with("failing_begin")
        expect(foo_plugin).to_not receive(:hook).with("failing_end")
        subject.send(:_supervise, foo_plugin, :failing)
      end
    end
  end

  describe ".stopping_symbol_for" do
    let(:guard_plugin) { instance_double(Guard::Plugin).as_null_object }

    context "for a group with :halt_on_fail" do
      before do
        allow(guard_plugin.group).to receive(:options) do
          { halt_on_fail: true }
        end
      end

      it "returns :no_catch" do
        symbol = described_class.stopping_symbol_for(guard_plugin)
        expect(symbol).to eq :no_catch
      end
    end

    context "for a group without :halt_on_fail" do
      before do
        allow(guard_plugin.group).to receive(:options) do
          { halt_on_fail: false }
        end
      end

      it "returns :task_has_failed" do
        symbol = described_class.stopping_symbol_for(guard_plugin)
        expect(symbol).to eq :task_has_failed
      end
    end
  end
end
