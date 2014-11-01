require "spec_helper"
require "guard/plugin"

describe Guard::Commander do
  let(:interactor) { instance_double(Guard::Interactor) }

  before do
    allow(Guard::Interactor).to receive(:new) { interactor }
  end

  describe ".start" do
    let(:runner) { instance_double(Guard::Runner, run: true) }
    let(:listener) do
      instance_double(Listen::Listener, start: true, stop: true)
    end

    let(:watched_dir) { Dir.pwd }

    before do
      allow(::Guard).to receive(:runner) { runner }
      allow(Listen).to receive(:to).with(watched_dir, {}) { listener }
      allow(Guard::Notifier).to receive(:turn_on)

      # Simulate Ctrl-D in Pry, or Ctrl-C in non-interactive mode
      allow(interactor).to receive(:foreground).and_return(:exit)

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    context "Guard has not been setuped" do
      it "calls Guard setup" do
        expect(::Guard).to receive(:setup).with(foo: "bar").and_call_original

        ::Guard.start(foo: "bar")
      end
    end

    it "displays an info message" do
      expect(::Guard::UI).to receive(:info).
        with("Guard is now watching at '#{Dir.pwd}'")

      ::Guard.start
    end

    it "tell the runner to run the :start task" do
      expect(runner).to receive(:run).with(:start)

      ::Guard.start
    end

    it "start the listener" do
      expect(listener).to receive(:start)

      ::Guard.start
    end
  end

  describe ".stop" do
    let(:runner) { instance_double(Guard::Runner, run: true) }
    let(:listener) { instance_double(Listen::Listener, stop: true) }

    before do
      allow(::Guard).to receive(:runner) { runner }
      allow(Listen).to receive(:to).with(Dir.pwd, {}) { listener }
      allow(Guard::Notifier).to receive(:turn_on)
      allow(listener).to receive(:stop)
      allow(interactor).to receive(:background)

      stub_guardfile(" ")
      stub_user_guard_rb
      Guard.setup
    end

    it "turns off the interactor" do
      expect(interactor).to receive(:background)
      ::Guard.stop
    end

    it "turns the notifier off" do
      expect(::Guard::Notifier).to receive(:turn_off)
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
    let(:runner) { instance_double(Guard::Runner, run: true) }
    let(:group) { ::Guard::Group.new("frontend") }
    subject { ::Guard.setup }

    before do
      allow(::Guard::Notifier).to receive(:turn_on)
      allow(::Guard).to receive(:runner) { runner }
      allow(::Guard).to receive(:scope) { {} }
      allow(::Guard::UI).to receive(:info)
      allow(::Guard::UI).to receive(:clear)
      allow(Listen).to receive(:to).with(Dir.pwd, {})

      stub_guardfile(" ")
      stub_user_guard_rb
    end

    it "clears the screen" do
      expect(::Guard::UI).to receive(:clear)

      subject.reload
    end

    context "with a given scope" do
      it "does not re-evaluate the Guardfile" do
        expect_any_instance_of(::Guard::Guardfile::Evaluator).
          to_not receive(:reevaluate_guardfile)

        subject.reload(groups: [group])
      end

      it "reloads Guard" do
        expect(runner).to receive(:run).with(:reload,  groups: [group])

        subject.reload(groups: [group])
      end
    end

    context "with an empty scope" do
      it "does re-evaluate the Guardfile" do
        expect_any_instance_of(::Guard::Guardfile::Evaluator).
          to receive(:reevaluate_guardfile)

        subject.reload
      end

      it "does not reload Guard" do
        expect(runner).to_not receive(:run).with(:reload, {})

        subject.reload
      end
    end
  end

  describe ".run_all" do
    let(:runner) { instance_double(Guard::Runner, run: true) }
    let(:group) { ::Guard::Group.new("frontend") }

    subject { ::Guard.setup }

    before do
      allow(::Guard::Notifier).to receive(:turn_on)
      allow(::Guard).to receive(:runner) { runner }
      allow(::Guard::UI).to receive(:action_with_scopes)
      allow(::Guard::UI).to receive(:clear)
      allow(Listen).to receive(:to).with(Dir.pwd, {})

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
      subject { ::Guard.setup }
      let(:listener) { instance_double(Listen::Listener) }

      before do
        allow(::Guard::Notifier).to receive(:turn_on)
        allow(Listen).to receive(:to).with(Dir.pwd, {}) { listener }
        allow(listener).to receive(:paused?) { false }

        stub_guardfile(" ")
        stub_user_guard_rb
      end

      [:toggle, nil, :paused].each do |mode|
        context "with #{mode.inspect}" do
          it "pauses" do
            expect(listener).to receive(:pause)
            subject.pause(mode)
          end
        end
      end

      context "with :unpaused" do
        it "does nothing" do
          expect(listener).to_not receive(:unpause)
          expect(listener).to_not receive(:pause)
          subject.pause(:unpaused)
        end
      end

      context "with invalid parameter" do
        it "raises an ArgumentError" do
          expect { subject.pause(:invalid) }.
            to raise_error(ArgumentError, "invalid mode: :invalid")
        end
      end
    end

    context "when already paused" do
      subject { ::Guard.setup }
      let(:listener) { instance_double(Listen::Listener) }

      before do
        allow(::Guard::Notifier).to receive(:turn_on)
        allow(Listen).to receive(:to).with(Dir.pwd, {}) { listener }
        allow(listener).to receive(:paused?) { true }

        stub_guardfile(" ")
        stub_user_guard_rb
      end

      [:toggle, nil, :unpaused].each do |mode|
        context "with #{mode.inspect}" do
          it "unpauses" do
            expect(listener).to receive(:unpause)
            subject.pause(mode)
          end
        end
      end

      context "with :paused" do
        it "does nothing" do
          expect(listener).to_not receive(:unpause)
          expect(listener).to_not receive(:pause)
          subject.pause(:paused)
        end
      end

      context "with invalid parameter" do
        it "raises an ArgumentError" do
          expect { subject.pause(:invalid) }.
            to raise_error(ArgumentError, "invalid mode: :invalid")
        end
      end
    end
  end
end
