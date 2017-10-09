require "guard/runner"

require "guard/plugin"

RSpec.describe Guard::Runner do
  let!(:engine) { Guard.init }
  let(:ui_config) { instance_double("Guard::UI::Config") }
  let!(:frontend_group) { Guard::Group.new(:frontend) }
  let!(:backend_group) { Guard::Group.new(:backend) }

  Guard::Foo = Class.new { include(Guard::API); def my_hard_task; end; }
  Guard::Bar = Class.new { include(Guard::API); def my_hard_task; end; }
  Guard::Baz = Class.new.include(Guard::API)

  subject { described_class.new(engine: engine) }

  before do
    engine.plugins.add(:foo, group: :backend)
    engine.plugins.add(:bar, group: :frontend)
    engine.plugins.add(:baz, group: :frontend)

    allow(Guard::UI::Config).to receive(:new).and_return(ui_config)
    Guard::UI.options = nil
  end

  after do
    Guard::UI.reset_logger
    Guard::UI.options = nil
  end

  let(:foo_plugin) { engine.plugins.find(:foo) }
  let(:bar_plugin) { engine.plugins.find(:bar) }
  let(:baz_plugin) { engine.plugins.find(:baz) }

  describe "#run" do
    before do
      allow(ui_config).to receive(:with_progname).and_yield
    end

    it "executes supervised task on all registered plugins implementing it" do
      [foo_plugin, bar_plugin].each do |plugin|
        expect(plugin).to receive(:my_hard_task)
      end

      subject.run(:my_hard_task)
    end

    it "marks an action as unit of work" do
      expect(Lumberjack).to receive(:unit_of_work)
      subject.run(:my_task)
    end

    context "with interrupted task" do
      before do
        allow(foo_plugin).to receive(:run_all).and_raise(Interrupt)
      end

      it "catches the thrown symbol" do
        expect { subject.run(:run_all) }.to_not throw_symbol(:task_has_failed)
      end
    end

    context "with a scope" do
      let(:scope_hash) { { plugins: :bar } }

      it "executes the supervised task on the specified plugin only" do
        expect(foo_plugin).to_not receive(:run_all)
        expect(bar_plugin).to receive(:run_all)
        expect(baz_plugin).to_not receive(:run_all)

        subject.run(:run_all, scope_hash)
      end
    end

    context "with no scope" do
      let(:scope_hash) { nil }

      it "executes the supervised task using current scope" do
        expect(foo_plugin).to receive(:run_all)
        expect(bar_plugin).to receive(:run_all)
        expect(baz_plugin).to receive(:run_all)

        subject.run(:run_all, scope_hash)
      end
    end

    context "with a task that throws :task_has_failed" do
      context "in a group" do
        context "with halt_on_fail: true" do
          before do
            bar_plugin.group.options[:halt_on_fail] = true

            expect(bar_plugin).to receive(:run_all) { throw :task_has_failed }
            expect(baz_plugin).to_not receive(:run_all)
          end

          it "throws :task_has_failed" do
            subject.run(:run_all, groups: :frontend)
          end
        end

        context "with halt_on_fail: false" do
          before do
            bar_plugin.group.options[:halt_on_fail] = false

            expect(bar_plugin).to receive(:run_all) { throw :task_has_failed }
            expect(baz_plugin).to receive(:run_all) { true }
          end

          it "catches :task_has_failed" do
            subject.run(:run_all, groups: :frontend)
          end
        end
      end
    end

    context "with a task that succeeds" do
      context "without any arguments" do
        before do
          allow(foo_plugin).to receive(:run_all) { true }
        end

        it "does not remove the Guard" do
          expect(engine.plugins).to_not receive(:remove)

          subject.run(:run_all, plugins: :foo)
        end

        it "returns the result of the task" do
          result = subject.run(:run_all, plugins: :foo)

          expect(result).to be_truthy
        end

        it "calls :begin and :end hooks" do
          expect(foo_plugin).to receive(:hook).
            with("run_all_begin")
          expect(foo_plugin).to receive(:hook).
            with("run_all_end", true)

          subject.run(:run_all, plugins: :foo)
        end

        it "passes the result of the supervised method to the :end hook" do
          expect(foo_plugin).to receive(:hook).
            with("run_all_begin")
          expect(foo_plugin).to receive(:hook).
            with("run_all_end", true)

          subject.run(:run_all, plugins: :foo)
        end
      end
    end

    context "with a task that raises an exception" do
      before do
        allow(foo_plugin).to receive(:run_all) { fail "I break your system" }
        allow(engine.plugins).to receive(:remove).with(foo_plugin)
      end

      it "removes the Guard" do
        expect(engine.plugins).to receive(:remove).with(foo_plugin) {}

        subject.run(:run_all, plugins: :foo)
      end

      it "display an error to the user" do
        expect(::Guard::UI).to receive :error
        expect(::Guard::UI).to receive :info

        subject.run(:run_all, plugins: :foo)
      end

      it "returns the exception" do
        failing_result = subject.send(:_supervise, foo_plugin, :run_all)

        expect(failing_result).to be_kind_of(Exception)
        expect(failing_result.message).to eq "I break your system"
      end

      it "calls the default begin hook but not the default end hook" do
        expect(foo_plugin).to receive(:hook).with("run_all_begin")
        expect(foo_plugin).to_not receive(:hook).with("run_all_end")

        subject.run(:run_all, plugins: :foo)
      end
    end
  end

  describe "#run_on_changes" do
    let(:changes) { [[], [], []] }
    let(:watcher_module) { Guard::Watcher }

    before do
      allow(watcher_module).to receive(:match_files) { [] }
      allow(Guard::UI).to receive(:clear)
      allow(ui_config).to receive(:with_progname).and_yield
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
          run_on_changes
          run_on_additions
          run_on_removals
        ).each do |task|
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

  describe ".stopping_symbol_for" do
    context "for a group with :halt_on_fail" do
      before { foo_plugin.group.options[:halt_on_fail] = true }

      it "returns :no_catch" do
        expect(described_class.stopping_symbol_for(foo_plugin)).to eq :no_catch
      end
    end

    context "for a group without :halt_on_fail" do
      before { foo_plugin.group.options[:halt_on_fail] = false }

      it "returns :task_has_failed" do
        expect(described_class.stopping_symbol_for(foo_plugin)).to eq :task_has_failed
      end
    end
  end
end
