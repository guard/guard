require "guard/commander"

RSpec.describe Guard::Commander do
  subject { Guard }

  let(:interactor) { instance_double("Guard::Interactor") }
  let(:runner) { instance_double("Guard::Runner", run: true) }

  let(:scope) { instance_double("Guard::Internals::Scope") }
  let(:state) { instance_double("Guard::Internals::State") }
  let(:session) { instance_double("Guard::Internals::Session") }

  before do
    allow(state).to receive(:scope).and_return(scope)
    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

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
      allow(session).to receive(:watchdirs).and_return(%w(dir1 dir2))
      allow(Guard).to receive(:interactor).and_return(interactor)

      # Simulate Ctrl-D in Pry, or Ctrl-C in non-interactive mode
      allow(interactor).to receive(:foreground).and_return(:exit)

      allow(interactor).to receive(:background)
      allow(Guard::Notifier).to receive(:disconnect)
    end

    it "calls Guard setup" do
      expect(Guard).to receive(:setup).with(foo: "bar")
      Guard.start(foo: "bar")
    end

    it "displays an info message" do
      expect(Guard::UI).to receive(:info).
        with("Guard is now watching at 'dir1', 'dir2'")

      Guard.start
    end

    it "tell the runner to run the :start task" do

      expect(runner).to receive(:run).with(:start)
      allow(listener).to receive(:stop)
      Guard.start
    end

    it "start the listener" do
      expect(listener).to receive(:start)

      Guard.start
    end

    context "when finished" do
      it "stops everything" do
        expect(interactor).to receive(:foreground).and_return(:exit)

        # From stop()
        expect(interactor).to receive(:background)
        expect(listener).to receive(:stop)
        expect(runner).to receive(:run).with(:stop)
        expect(Guard::UI).to receive(:info).with("Bye bye...", reset: true)

        Guard.start
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

      Guard.stop
    end

    it "turns off the interactor" do
      expect(interactor).to have_received(:background)
    end

    it "turns the notifier off" do
      expect(Guard::Notifier).to have_received(:disconnect)
    end

    it "tell the runner to run the :stop task" do
      expect(runner).to have_received(:run).with(:stop)
    end

    it "stops the listener" do
      expect(listener).to have_received(:stop)
    end
  end

  describe ".reload" do
    let(:runner) { instance_double("Guard::Runner", run: true) }
    let(:group) { instance_double("Guard::Group", name: "frontend") }

    before do
      allow(Guard::Notifier).to receive(:connect)
      allow(Guard::UI).to receive(:info)
      allow(Guard::UI).to receive(:clear)

      allow(scope).to receive(:titles).and_return(["all"])

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    it "clears the screen" do
      expect(Guard::UI).to receive(:clear)

      Guard.reload
    end

    it "reloads Guard" do
      expect(runner).to receive(:run).with(:reload,  groups: [group])
      Guard.reload(groups: [group])
    end
  end

  describe ".run_all" do
    let(:group) { instance_double("Guard::Group", name: "frontend") }

    before do
      allow(::Guard::Notifier).to receive(:connect)
      allow(::Guard::UI).to receive(:action_with_scopes)
      allow(::Guard::UI).to receive(:clear)
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
