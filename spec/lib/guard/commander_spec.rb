require "guard/commander"

RSpec.describe Guard::Commander do
  let(:interactor) { instance_double("Guard::Interactor") }
  let(:runner) { instance_double("Guard::Runner", run: true) }

  before do
    allow(Guard::Interactor).to receive(:new) { interactor }
    allow(Guard::Runner).to receive(:new).and_return(runner)
  end

  describe ".start" do
    let(:listener) do
      instance_double("Listen::Listener", start: true, stop: true)
    end

    let(:watched_dir) { Dir.pwd }

    before do
      stub_guardfile(" ")
      stub_user_guard_rb

      # from stop()
      allow(Guard).to receive(:setup)
      allow(Guard).to receive(:listener).and_return(listener)
      allow(Guard).to receive(:watchdirs).and_return(%w(dir1 dir2))
      allow(Guard).to receive(:interactor).and_return(interactor)

      # Simulate Ctrl-D in Pry, or Ctrl-C in non-interactive mode
      allow(interactor).to receive(:foreground).and_return(:exit)

      allow(interactor).to receive(:background)
      allow(Guard::Notifier).to receive(:disconnect)
    end

    it "calls Guard setup" do
      expect(::Guard).to receive(:setup).with(foo: "bar")
      ::Guard.start(foo: "bar")
    end

    it "displays an info message" do
      expect(::Guard::UI).to receive(:info).
        with("Guard is now watching at 'dir1', 'dir2'")

      ::Guard.start
    end

    it "tell the runner to run the :start task" do

      expect(runner).to receive(:run).with(:start)
      allow(listener).to receive(:stop)
      ::Guard.start
    end

    it "start the listener" do
      expect(listener).to receive(:start)

      ::Guard.start
    end

    context "when finished" do
      it "stops everything" do
        expect(interactor).to receive(:foreground).and_return(:exit)

        # From stop()
        expect(interactor).to receive(:background)
        expect(listener).to receive(:stop)
        expect(runner).to receive(:run).with(:stop)
        expect(::Guard::UI).to receive(:info).with("Bye bye...", reset: true)

        ::Guard.start
      end
    end
  end

  describe ".stop" do
    let(:runner) { instance_double("Guard::Runner", run: true) }
    let(:listener) { instance_double("Listen::Listener", stop: true) }

    before do
      allow(Guard::Notifier).to receive(:disconnect)
      allow(Guard).to receive(:listener).and_return(listener)
      allow(listener).to receive(:stop)
      allow(Guard).to receive(:interactor).and_return(interactor)
      allow(interactor).to receive(:background)

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    it "turns off the interactor" do
      expect(interactor).to receive(:background)
      ::Guard.stop
    end

    it "turns the notifier off" do
      expect(::Guard::Notifier).to receive(:disconnect)
      ::Guard.stop
    end

    it "tell the runner to run the :stop task" do
      expect(runner).to receive(:run).with(:stop)
      ::Guard.stop
    end

    it "stops the listener" do
      expect(listener).to receive(:stop)
      ::Guard.stop
    end
  end

  describe ".reload" do
    let(:runner) { instance_double("Guard::Runner", run: true) }
    let(:group) { ::Guard::Group.new("frontend") }
    let(:evaluator) { instance_double("Guard::Guardfile::Evaluator") }

    before do
      allow(::Guard::Notifier).to receive(:connect)
      allow(::Guard).to receive(:scope) { {} }
      allow(::Guard::UI).to receive(:info)
      allow(::Guard::UI).to receive(:clear)

      allow(::Guard::Guardfile::Evaluator).to receive(:new).
        and_return(evaluator)

      allow(evaluator).to receive(:reevaluate_guardfile)

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    it "clears the screen" do
      expect(::Guard::UI).to receive(:clear)

      Guard.reload
    end

    context "with a given scope" do
      it "does not re-evaluate the Guardfile" do
        expect(evaluator).to_not receive(:reevaluate_guardfile)

        Guard.reload(groups: [group])
      end

      it "reloads Guard" do
        expect(runner).to receive(:run).with(:reload,  groups: [group])

        Guard.reload(groups: [group])
      end
    end

    context "with an empty scope" do
      it "does re-evaluate the Guardfile" do
        expect(evaluator).to receive(:reevaluate_guardfile)

        Guard.reload
      end

      it "does not reload Guard" do
        expect(runner).to_not receive(:run).with(:reload, {})

        Guard.reload
      end
    end
  end

  describe ".run_all" do
    let(:group) { ::Guard::Group.new("frontend") }

    subject do
      Guard
    end

    before do
      allow(::Guard::Notifier).to receive(:connect)
      allow(::Guard::UI).to receive(:action_with_scopes)
      allow(::Guard::UI).to receive(:clear)

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    context "with a given scope" do
      it "runs all with the scope" do
        expect(runner).to receive(:run).with(:run_all,  groups: [group])

        subject.run_all(groups: [group])
      end
    end

    context "with an empty scope" do
      it "runs all" do
        expect(runner).to receive(:run).with(:run_all, {})

        subject.run_all
      end
    end
  end

  describe ".pause" do
    context "when unpaused" do
      let(:listener) { instance_double("Listen::Listener") }

      before do
        allow(::Guard::Notifier).to receive(:connect)
        allow(Guard).to receive(:listener).and_return(listener)
        allow(listener).to receive(:paused?) { false }

        stub_guardfile(" ")
        stub_user_guard_rb
      end

      [:toggle, nil, :paused].each do |mode|
        context "with #{mode.inspect}" do
          it "pauses" do
            expect(listener).to receive(:pause)
            Guard.pause(mode)
          end
        end
      end

      context "with :unpaused" do
        it "does nothing" do
          expect(listener).to_not receive(:unpause)
          expect(listener).to_not receive(:pause)
          Guard.pause(:unpaused)
        end
      end

      context "with invalid parameter" do
        it "raises an ArgumentError" do
          expect { Guard.pause(:invalid) }.
            to raise_error(ArgumentError, "invalid mode: :invalid")
        end
      end
    end

    context "when already paused" do
      let(:listener) { instance_double("Listen::Listener") }

      before do
        allow(::Guard::Notifier).to receive(:connect)
        allow(Guard).to receive(:listener).and_return(listener)
        allow(listener).to receive(:paused?) { true }

        stub_guardfile(" ")
        stub_user_guard_rb
      end

      [:toggle, nil, :unpaused].each do |mode|
        context "with #{mode.inspect}" do
          it "unpauses" do
            expect(listener).to receive(:unpause)
            Guard.pause(mode)
          end
        end
      end

      context "with :paused" do
        it "does nothing" do
          expect(listener).to_not receive(:unpause)
          expect(listener).to_not receive(:pause)
          Guard.pause(:paused)
        end
      end

      context "with invalid parameter" do
        it "raises an ArgumentError" do
          expect { Guard.pause(:invalid) }.
            to raise_error(ArgumentError, "invalid mode: :invalid")
        end
      end
    end
  end

  describe ".show" do
    let(:dsl_describer) { instance_double("Guard::DslDescriber") }

    before do
      allow(Guard::DslDescriber).to receive(:new).with(no_args).
        and_return(dsl_describer)
    end

    it "shows list of plugins" do
      expect(dsl_describer).to receive(:show)
      Guard.show
    end
  end
end
