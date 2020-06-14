# frozen_string_literal: true

require "guard/runner"

RSpec.describe Guard::Runner, :stub_ui do
  include_context "with engine"

  let(:frontend_group) { engine.groups.add(:frontend) }
  let(:backend_group) { engine.groups.add(:backend) }
  let!(:dummy_plugin) { plugins.add("dummy", group: frontend_group, watchers: [Guard::Watcher.new("hello")]) }
  let!(:doe_plugin) { plugins.add("doe", group: frontend_group) }
  let!(:foobar_plugin) { plugins.add("foobar", group: backend_group) }
  let!(:foobaz_plugin) { plugins.add("foobaz", group: backend_group) }

  after do
    Guard::UI.reset
  end

  subject { described_class.new(engine.session) }

  describe "#run" do
    it "executes supervised task on all registered plugins implementing it" do
      [dummy_plugin, doe_plugin, foobar_plugin, foobaz_plugin].each do |plugin|
        expect(plugin).to receive(:title)
      end

      subject.run(:title)
    end

    it "marks an action as unit of work" do
      expect(Lumberjack).to receive(:unit_of_work)
      subject.run(:my_task)
    end

    context "with interrupted task" do
      before do
        allow(dummy_plugin).to receive(:title).and_raise(Interrupt)
      end

      it "catches the thrown symbol" do
        expect { subject.run(:title) }.to_not throw_symbol(:task_has_failed)
      end
    end

    [:dummy, [:dummy]].each do |entries|
      context "with entries: #{entries}" do
        it "executes the supervised task on the specified plugin only" do
          expect(dummy_plugin).to receive(:title)
          [doe_plugin, foobar_plugin, foobaz_plugin].each do |plugin|
            expect(plugin).to_not receive(:title)
          end

          subject.run(:title, entries)
        end
      end
    end

    context "with no scope" do
      it "executes the supervised task using current scope" do
        [dummy_plugin, doe_plugin, foobar_plugin, foobaz_plugin].each do |plugin|
          expect(plugin).to receive(:title)
        end

        subject.run(:title)
      end
    end
  end

  describe "#run_on_changes" do
    let(:matching_files) { ["hello"] }

    shared_examples "cleared terminal" do
      it "always calls UI.clearable!" do
        expect(Guard::UI).to receive(:clearable!)

        subject.run_on_changes(*changes)
      end

      context "when clearable" do
        it "clear UI" do
          expect(Guard::UI).to receive(:clear).exactly(4).times

          subject.run_on_changes(*changes)
        end
      end
    end

    context "with no changes" do
      let(:changes) { [[], [], []] }

      it_behaves_like "cleared terminal"

      it "does not run any task" do
        %w[
          run_on_modifications
          run_on_change
          run_on_additions
          run_on_removals
          run_on_deletion
        ].each do |task|
          expect(dummy_plugin).to_not receive(task.to_sym)
        end

        subject.run_on_changes(*changes)
      end
    end

    context "with non-matching modified paths" do
      let(:changes) { [%w[file.txt image.png], [], []] }

      it "does not call run anything" do
        expect(dummy_plugin).to_not receive(:run_on_modifications)

        subject.run_on_changes(*changes)
      end
    end

    context "with matching modified paths" do
      let(:changes) { [matching_files, [], []] }

      it "executes the :run_first_task_found task" do
        expect(dummy_plugin).to receive(:run_on_modifications).with(matching_files) {}

        subject.run_on_changes(*changes)
      end
    end

    context "with non-matching added paths" do
      let(:changes) { [[], %w[file.txt image.png], []] }

      it "does not call run anything" do
        expect(dummy_plugin).to_not receive(:run_on_additions)

        subject.run_on_changes(*changes)
      end
    end

    context "with matching added paths" do
      let(:changes) { [[], matching_files, []] }

      it "executes the :run_on_additions task" do
        expect(dummy_plugin).to receive(:run_on_additions).with(matching_files) {}

        subject.run_on_changes(*changes)
      end
    end

    context "with non-matching removed paths" do
      let(:removed) { %w[file.txt image.png] }
      let(:changes) { [[], [], %w[file.txt image.png]] }

      it "does not call tasks" do
        expect(dummy_plugin).to_not receive(:run_on_removals)

        subject.run_on_changes(*changes)
      end
    end

    context "with matching removed paths" do
      let(:changes) { [[], [], matching_files] }

      it "executes the :run_on_removals task" do
        expect(dummy_plugin).to receive(:run_on_removals).with(matching_files) {}

        subject.run_on_changes(*changes)
      end
    end
  end

  describe "#_supervise" do
    it "executes the task on the passed plugin" do
      expect(dummy_plugin).to receive(:title)

      subject.__send__(:_supervise, dummy_plugin, :title)
    end

    context "with a task that succeeds" do
      context "without any arguments" do
        it "does not remove the plugin" do
          expect(plugins).to_not receive(:remove)

          subject.__send__(:_supervise, dummy_plugin, :title)
        end

        it "returns the result of the task" do
          result = subject.__send__(:_supervise, dummy_plugin, :title)

          expect(result).to be_truthy
        end

        it "calls :begin and :end hooks and passes the result of the supervised method to the :end hook" do
          expect(dummy_plugin).to receive(:hook)
            .with("title_begin")

          expect(dummy_plugin).to receive(:hook)
            .with("title_end", "Dummy")

          subject.__send__(:_supervise, dummy_plugin, :title)
        end
      end

      context "with arguments" do
        it "does not remove the Guard" do
          expect(plugins).to_not receive(:remove)

          subject.__send__(
            :_supervise,
            dummy_plugin,
            :run_on_changes,
            "given_path"
          )
        end

        it "returns the result of the task" do
          result = subject.__send__(
            :_supervise,
            dummy_plugin,
            :run_on_changes,
            "given_path"
          )

          expect(result).to eq "I'm a success"
        end
      end
    end

    context "with a task that throws :task_has_failed" do
      context "in a group" do
        context "with halt_on_fail: true" do
          before { frontend_group.options[:halt_on_fail] = true }

          it "throws :task_has_failed" do
            expect do
              subject.__send__(:_supervise, dummy_plugin, :throwing)
            end.to throw_symbol(:task_has_failed)
          end
        end

        context "with halt_on_fail: false" do
          before { frontend_group.options[:halt_on_fail] = false }

          it "catches :task_has_failed" do
            expect do
              subject.__send__(:_supervise, dummy_plugin, :throwing)
            end.to_not throw_symbol(:task_has_failed)
          end
        end
      end
    end

    context "with a task that raises an exception" do
      it "removes the plugin" do
        expect(plugins).to receive(:remove).with(dummy_plugin) {}

        subject.__send__(:_supervise, dummy_plugin, :failing)
      end

      it "display an error to the user" do
        expect(::Guard::UI).to receive :error
        expect(::Guard::UI).to receive :info

        subject.__send__(:_supervise, dummy_plugin, :failing)
      end

      it "returns the exception" do
        failing_result = subject.__send__(:_supervise, dummy_plugin, :failing)

        expect(failing_result).to be_kind_of(Exception)
        expect(failing_result.message).to eq "I break your system"
      end

      it "calls the default begin hook but not the default end hook" do
        expect(dummy_plugin).to receive(:hook).with("failing_begin")
        expect(dummy_plugin).to_not receive(:hook).with("failing_end")

        subject.__send__(:_supervise, dummy_plugin, :failing)
      end
    end
  end
end
