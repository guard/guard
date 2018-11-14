# frozen_string_literal: true

require "guard/commander"

RSpec.describe Guard::Commander do
  let!(:engine) { Guard.init }

  subject { engine }

  let(:interactor) { instance_double("Guard::Interactor") }
  let(:runner) { instance_double("Guard::Runner", run: true) }

  let(:scope) { instance_double("Guard::Internals::Scope") }
  let(:state) { instance_double("Guard::Internals::State") }
  let(:session) { instance_double("Guard::Internals::Session") }

  before do
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

      # Simulate Ctrl-D in Pry, or Ctrl-C in non-interactive mode
      allow(interactor).to receive(:foreground).and_return(:exit)

      allow(interactor).to receive(:background)
      allow(Guard::Notifier).to receive(:connect)
      allow(Guard::Notifier).to receive(:disconnect)
    end

    it "calls Guard.init" do
      expect(engine).to receive(:setup).with(foo: "bar")

      subject.start(foo: "bar")
    end

    it "displays an info message" do
      expect(Guard::UI).to receive(:info)
        .with("Guard is now watching at 'dir1', 'dir2'")

      subject.start
    end

    it "tell the runner to run the :start task" do
      expect(runner).to receive(:run).with(:start)
      allow(listener).to receive(:stop)
      subject.start
    end

    it "start the listener" do
      expect(listener).to receive(:start)

      subject.start
    end

    context "when finished" do
      it "stops everything" do
        expect(interactor).to receive(:foreground).and_return(:exit)

        # From stop()
        expect(interactor).to receive(:background)
        expect(listener).to receive(:stop)
        expect(runner).to receive(:run).with(:stop)
        expect(Guard::UI).to receive(:info).with("Bye bye...", reset: true)

        subject.start
      end
    end

    context "when listener.start raises an error" do
      it "calls Commander#stop" do
        allow(listener).to receive(:start).and_raise(RuntimeError)

        # From stop()
        expect(interactor).to receive(:background)
        expect(listener).to receive(:stop)
        expect(runner).to receive(:run).with(:stop)
        expect(Guard::UI).to receive(:info).with("Bye bye...", reset: true)

        expect { Guard.start }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#stop" do
    let(:runner) { instance_double("Guard::Runner", run: true) }
    let(:listener) { instance_double("Listen::Listener", stop: true) }

    before do
      allow(Guard::Notifier).to receive(:disconnect)
      allow(Guard).to receive(:listener).and_return(listener)
      allow(listener).to receive(:stop)
      allow(Guard).to receive(:interactor).and_return(interactor)
      allow(interactor).to receive(:background)

      subject.stop
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
      # allow(Guard::UI).to receive(:info)
      # allow(Guard::UI).to receive(:clear)

      allow(subject.scope).to receive(:titles).and_return(["all"])

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    it "clears the screen" do
      expect(Guard::UI).to receive(:clear)

      subject.reload
    end

    it "reloads Guard" do
      expect(runner).to receive(:run).with(:reload, groups: [group])

      subject.reload(groups: [group])
    end
  end

  describe ".run_all" do
    let(:group) { instance_double("Guard::Group", name: "frontend") }

    before do
      allow(::Guard::Notifier).to receive(:connect)
      allow(::Guard::UI).to receive(:action_with_scopes)
      # allow(::Guard::UI).to receive(:clear)
    end

    context "with a given scope" do
      it "runs all with the scope" do
        expect(runner).to receive(:run).with(:run_all, groups: [group])

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
        # allow(Guard).to receive(:listener).and_return(listener)
        allow(subject.listener).to receive(:paused?) { false }
      end

      [:toggle, nil, :paused].each do |mode|
        context "with #{mode.inspect}" do
          before do
            allow(subject.listener).to receive(:pause)
          end

          it "pauses" do
            expect(subject.listener).to receive(:pause)

            subject.pause(mode)
          end

          it "shows a message" do
            expected = /File event handling has been paused/
            expect(Guard::UI).to receive(:info).with(expected)

            subject.pause(mode)
          end
        end
      end

      context "with :unpaused" do
        it "does nothing" do
          expect(subject.listener).to_not receive(:start)
          expect(subject.listener).to_not receive(:pause)

          subject.pause(:unpaused)
        end
      end

      context "with invalid parameter" do
        it "raises an ArgumentError" do
          expect { Guard.pause(:invalid) }
            .to raise_error(ArgumentError, "invalid mode: :invalid")
        end
      end
    end

    context "when already paused" do
      let(:listener) { instance_double("Listen::Listener") }

      before do
        allow(::Guard::Notifier).to receive(:connect)
        # allow(Guard).to receive(:listener).and_return(listener)
        allow(subject.listener).to receive(:paused?) { true }
      end

      [:toggle, nil, :unpaused].each do |mode|
        context "with #{mode.inspect}" do
          before do
            allow(subject.listener).to receive(:start)
          end

          it "unpauses" do
            expect(subject.listener).to receive(:start)

            subject.pause(mode)
          end

          it "shows a message" do
            expected = /File event handling has been resumed/
            expect(Guard::UI).to receive(:info).with(expected)

            subject.pause(mode)
          end
        end
      end

      context "with :paused" do
        it "does nothing" do
          expect(subject.listener).to_not receive(:start)
          expect(subject.listener).to_not receive(:pause)

          subject.pause(:paused)
        end
      end

      context "with invalid parameter" do
        it "raises an ArgumentError" do
          expect { subject.pause(:invalid) }
            .to raise_error(ArgumentError, "invalid mode: :invalid")
        end
      end
    end
  end

  describe ".show" do
    let(:dsl_describer) { instance_double("Guard::DslDescriber") }

    before do
      allow(Guard::DslDescriber).to receive(:new).with(no_args)
                                                 .and_return(dsl_describer)
    end

    it "shows list of plugins" do
      expect(dsl_describer).to receive(:show)

      subject.show
    end
  end
end
