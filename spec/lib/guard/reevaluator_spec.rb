require "guard/reevaluator.rb"

RSpec.describe Guard::Reevaluator, exclude_stubs: Guard::Plugin do
  let(:options) { {} }
  subject { described_class.new(options) }

  let(:evaluator) { instance_double("Guard::Guardfile::Evaluator") }
  let(:runner) { instance_double("Guard::Runner") }

  let(:session) { instance_double("Guard::Internals::Session") }
  let(:state) { instance_double("Guard::Internals::State") }
  let(:plugins) { instance_double("Guard::Internals::Plugins") }
  let(:groups) { instance_double("Guard::Internals::Groups") }
  let(:default) { instance_double("Guard::Group") }

  before do
    allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)
    allow(Guard::Runner).to receive(:new).and_return(runner)
    allow(evaluator).to receive(:path).and_return(Pathname("Guardfile"))

    allow(plugins).to receive(:all).and_return([])

    allow(session).to receive(:evaluator_options).and_return(guardfile: nil)
    allow(session).to receive(:notify_options).and_return(notify: true)
    allow(session).to receive(:plugins).and_return(plugins)
    allow(session).to receive(:groups).and_return(groups)

    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

    allow(groups).to receive(:add).with(:default).and_return(default)
  end

  context "when Guardfile is modified" do
    let(:watcher) { instance_double("Guard::Watcher") }

    before do
      allow(plugins).to receive(:add).with(:reevaluator, anything)
      allow(Guard::Watcher).to receive(:new). and_return(watcher)

      allow(state).to receive(:reset_session)
      allow(evaluator).to receive(:evaluate)
      allow(runner).to receive(:run)
      allow(Guard::Notifier).to receive(:connect)
      allow(Guard::Notifier).to receive(:disconnect)
      allow(Guard::Notifier).to receive(:notify)
    end

    context "when inline" do
      before do
        allow(evaluator).to receive(:inline?).and_return(true)
      end

      it "should not reevaluate" do
        expect(evaluator).to_not receive(:evaluate)
        subject.run_on_modifications(["Guardfile"])
      end
    end

    context "when not inline" do
      before do
        allow(evaluator).to receive(:inline?).and_return(false)
      end

      it "should reset the session" do
        expect(state).to receive(:reset_session)
        subject.run_on_modifications(["Guardfile"])
      end

      it "should reevaluate" do
        expect(evaluator).to receive(:evaluate)
        subject.run_on_modifications(["Guardfile"])
      end
    end

    context "when Guardfile contains errors" do
      let(:failure) { proc { fail Guard::Dsl::Error, "Could not load Foo!" } }

      before do
        allow(evaluator).to receive(:evaluate) { failure.call }
        allow(evaluator).to receive(:inline?).and_return(false)
      end

      context "with a Dsl error" do
        let(:failure) { proc { fail Guard::Dsl::Error, "Something failed!" } }

        it "notifies guard it failed to prevent being fired" do
          expect { subject.run_on_modifications(["Guardfile"]) }.
            to throw_symbol(:task_has_failed)
        end
      end

      context "with a Guardfile error" do
        let(:failure) do
          proc { fail Guard::Guardfile::Evaluator::Error, "Failed!" }
        end

        it "should notify guard it failed to prevent being fired" do
          expect { subject.run_on_modifications(["Guardfile"]) }.
            to throw_symbol(:task_has_failed)
        end
      end

      # TODO: show backtrace?
      it "should show warning about the error" do
        expect(Guard::UI).to receive(:warning).
          with("Failed to reevaluate file: Could not load Foo!")

        catch(:task_has_failed) do
          subject.run_on_modifications(["Guardfile"])
        end
      end

      it "should notify eval failed with a :task_has_failed error" do
        expect { subject.run_on_modifications(["Guardfile"]) }.
          to throw_symbol(:task_has_failed)
      end

      it "should add itself as an active plugin" do
        watcher = instance_double(Guard::Watcher)

        # TODO: the right pattern? Other custom Guardfile locations?
        expect(Guard::Watcher).to receive(:new).with("Guardfile").
          and_return(watcher)

        options = { watchers: [watcher], group: :common }
        expect(plugins).to receive(:add).with(:reevaluator, options)

        catch(:task_has_failed) do
          subject.run_on_modifications(["Guardfile"])
        end
      end
    end
  end

  context "when Guardfile is not modified" do
    it "should not reevaluate guardfile" do
      expect(evaluator).to_not receive(:evaluate)
      subject.run_on_modifications(["foo"])
    end
  end

  describe ".reevaluate" do

    before do
      allow(runner).to receive(:run)

      # TODO: not tested properly
      allow(Guard::Notifier).to receive(:connect)
      allow(Guard::Notifier).to receive(:disconnect)
      allow(Guard::Notifier).to receive(:notify)
      allow(evaluator).to receive(:inline?).and_return(false)
      allow(evaluator).to receive(:evaluate)

      allow(state).to receive(:reset_session)
    end

    context "before reevaluation" do
      before do
        allow(runner).to receive(:run).with(:stop)
        allow(runner).to receive(:run).with(:start)
      end

      after { subject.reevaluate }

      it "stops all Guards" do
        allow(evaluator).to receive(:evaluate) do
          expect(runner).to have_received(:run).with(:stop)
        end
      end

      it "clears the notifiers" do
        allow(evaluator).to receive(:evaluate) do
          expect(Guard::Notifier).to have_received(:disconnect)
        end
      end

      it "resets the session" do
        allow(evaluator).to receive(:evaluate) do
          expect(state).to have_received(:reset_session)
        end
      end
    end

    it "evaluates the Guardfile" do
      allow(evaluator).to receive(:evaluate)
      allow(Guard).to receive(:_pluginless_guardfile?).and_return(false)
      subject.reevaluate
    end

    describe "after reevaluation" do
      context "with notifications enabled" do
        before { allow(Guard::Notifier).to receive(:enabled?) { true } }

        it "enables the notifications again" do
          expect(Guard::Notifier).to receive(:connect)
          subject.reevaluate
        end
      end

      # TODO: test probably doesn't make sense anymore, since on/off
      # was replace with connect/disconnect
      context "with notifications disabled" do
        before { allow(Guard::Notifier).to receive(:enabled?) { false } }

        it "it still gets connected" do
          expect(Guard::Notifier).to receive(:connect)
          subject.reevaluate
        end
      end

      context "with Guards afterwards" do
        before do
          allow(runner).to receive(:run)
        end

        it "shows a success message" do
          allow(Guard).to receive(:_pluginless_guardfile?).and_return(false)
          expect(Guard::UI).to receive(:info).
            with("Guardfile has been re-evaluated.")
          subject.reevaluate
        end

        it "shows a success notification" do
          expect(Guard::Notifier).to receive(:notify).
            with("Guardfile has been re-evaluated.", title: "Guard re-evaluate")

          allow(Guard).to receive(:_pluginless_guardfile?).and_return(false)
          subject.reevaluate
        end

        it "starts all Guards" do
          allow(Guard).to receive(:_pluginless_guardfile?).and_return(false)
          expect(runner).to receive(:run).with(:start)
          subject.reevaluate
        end
      end

      context "without Guards afterwards" do
        it "shows a failure notification" do
          # TODO: temporary hack to continue refactoring notifier
          # TODO: this whole spec needs stubbing
          foo = instance_double("Guard::Plugin", name: "reevaluator")
          allow(plugins).to receive(:all).and_return([foo])

          expect(Guard::Notifier).to receive(:notify).
            with(
              "No plugins found in Guardfile, please add at least one.",
              title: "Guard re-evaluate",
              image: :failed)
          subject.reevaluate
        end
      end
    end
  end
end
