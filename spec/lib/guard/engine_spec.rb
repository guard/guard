# frozen_string_literal: true

require "guard/engine"
require "guard/plugin"
require "guard/jobs/pry_wrapper"
require "guard/jobs/sleep"

RSpec.describe Guard::Engine, :stub_ui do
  include_context "with engine"

  let(:traps) { Guard::Internals::Traps }

  describe "#state" do
    it "passes options to #state" do
      expect(Guard::Internals::State).to receive(:new).with(engine, options).and_call_original

      engine.state
    end
  end

  describe "#start" do
    subject(:start_engine) { engine.start }

    before do
      allow(engine.__send__(:_runner)).to receive(:run).with(:start)
      allow(engine.__send__(:_runner)).to receive(:run).with(:stop)
    end

    after { engine.stop }

    it "connects to the notifier" do
      expect(Guard::Notifier).to receive(:connect).with(engine.state.session.notify_options)

      start_engine
    end

    describe "listener initialization" do
      let(:options) { base_options.merge(watchdirs: "/foo", latency: 2, wait_for_delay: 1) }

      it "initializes the listener" do
        expect(Listen).to receive(:to)
          .with("/foo", latency: 2, wait_for_delay: 1).and_return(listener)

        start_engine
      end
    end

    describe "signals trapping" do
      before do
        allow(traps).to receive(:handle)
      end

      it "sets up USR1 trap for pausing" do
        expect(traps).to receive(:handle).with("USR1") { |_, &b| b.call }
        expect(engine).to receive(:async_queue_add)
          .with(%i[guard_pause paused])

        start_engine
      end

      it "sets up USR2 trap for unpausing" do
        expect(traps).to receive(:handle).with("USR2") { |_, &b| b.call }
        expect(engine).to receive(:async_queue_add)
          .with(%i[guard_pause unpaused])

        start_engine
      end

      it "sets up INT trap for cancelling or quitting interactor" do
        expect(traps).to receive(:handle).with("INT") { |_, &b| b.call }
        expect(interactor).to receive(:handle_interrupt)

        start_engine
      end
    end

    describe "interactor initialization" do
      it "initializes the interactor" do
        expect(Guard::Interactor).to receive(:new).with(engine, false)

        start_engine
      end
    end

    it "evaluates the Guardfile" do
      expect(engine.evaluator).to receive(:evaluate).and_call_original

      start_engine
    end

    describe "listener" do
      subject { listener }
      before { start_engine }

      context "with ignores 'ignore(/foo/)' and 'ignore!(/bar/)'" do
        let(:inline_guardfile) { "ignore(/foo/); ignore!(/bar/); guard :dummy" }

        it { is_expected.to have_received(:ignore).with([/foo/]) }
        it { is_expected.to have_received(:ignore!).with([/bar/]) }
      end

      context "without ignores" do
        it { is_expected.to_not have_received(:ignore) }
        it { is_expected.to_not have_received(:ignore!) }
      end
    end

    context "no plugins given" do
      let(:options) { { inline: "" } }

      it "displays an error message when no guard are defined in Guardfile" do
        expect(Guard::UI).to receive(:error)
          .with("No Guard plugins found in Guardfile, please add at least one.")

        start_engine
      end
    end

    describe "#interactor" do
      context "with interactions enabled" do
        let(:type) { :pry_wrapper }
        let(:options) { { inline: "guard :dummy", no_interactions: false } }

        it "initializes a new interactor" do
          expect(Guard::Interactor).to receive(:new).with(engine, true)

          start_engine
        end
      end

      context "with interactions disabled" do
        let(:type) { :sleep }
        let(:options) { { inline: "guard :dummy", no_interactions: true } }

        it "does not initialize a new interactor" do
          expect(Guard::Interactor).to receive(:new).with(engine, false)

          start_engine
        end
      end
    end

    describe "UI" do
      subject { Guard::UI }

      context "when clearing is configured" do
        before { start_engine }

        it { is_expected.to have_received(:reset_and_clear) }
      end
    end

    it "displays an info message" do
      expect(Guard::UI).to receive(:debug)
        .with("Guard starts all plugins")
      expect(Guard::UI).to receive(:info)
        .with("Using inline Guardfile.")
      expect(Guard::UI).to receive(:info)
        .with("Guard is now watching at '#{Dir.pwd}'")

      start_engine
    end

    it "tell the runner to run the :start task" do
      expect(engine.__send__(:_runner)).to receive(:run).with(:start)

      start_engine
    end

    it "start the listener" do
      expect(listener).to receive(:start)

      start_engine
    end

    context "when finished" do
      it "stops everything" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:start)
        expect(interactor).to receive(:foreground).and_return(:exit)

        # From stop()
        expect(interactor).to receive(:background)
        expect(listener).to receive(:stop)
        expect(engine.__send__(:_runner)).to receive(:run).with(:stop)
        expect(Guard::UI).to receive(:info).with("Bye bye...", reset: true)

        start_engine
      end
    end

    context "when listener.start raises an error" do
      it "calls #stop" do
        allow(listener).to receive(:start).and_raise(RuntimeError)

        # From stop()
        expect(interactor).to receive(:background)
        expect(listener).to receive(:stop)
        expect(engine.__send__(:_runner)).to receive(:run).with(:stop)
        expect(Guard::UI).to receive(:info).with("Bye bye...", reset: true)

        expect { start_engine }.to raise_error(RuntimeError)
      end
    end

    context "when setup raises an error" do
      it "calls #stop" do
        # Reproduce a case where an error is raised during Guardfile evaluation
        # before the listener and interactor are instantiated.
        expect(engine).to receive(:setup).and_raise(RuntimeError)

        # From stop()
        expect(engine.__send__(:_runner)).to receive(:run).with(:stop)
        expect(Guard::UI).to receive(:info).with("Bye bye...", reset: true)

        expect { start_engine }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#stop" do
    it "connects to the notifier" do
      expect(listener).to receive(:stop)
      expect(interactor).to receive(:background)
      expect(Guard::UI).to receive(:debug).with("Guard stops all plugins")
      expect(engine.__send__(:_runner)).to receive(:run).with(:stop)
      expect(Guard::Notifier).to receive(:disconnect)
      expect(Guard::UI).to receive(:info).with("Bye bye...", reset: true)

      engine.stop
    end

    it "turns off the interactor" do
      expect(interactor).to receive(:background)

      engine.stop
    end

    it "turns the notifier off" do
      expect(Guard::Notifier).to receive(:disconnect)

      engine.stop
    end

    it "tell the runner to run the :stop task" do
      expect(engine.__send__(:_runner)).to receive(:run).with(:stop)

      engine.stop
    end

    it "stops the listener" do
      expect(listener).to receive(:stop)

      engine.stop
    end
  end

  describe "#reload" do
    before do
      allow(engine.__send__(:_runner)).to receive(:run)
      engine.setup
    end

    it "clears the screen and prints information message" do
      expect(Guard::UI).to receive(:clear)
      expect(Guard::UI).to receive(:action_with_scopes).with("Reload", engine.session.scope_titles({}))

      engine.reload
    end

    context "with an empty scope" do
      it "runs all" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:reload, [])

        engine.reload
      end
    end

    context "with a given scope" do
      it "runs all with the scope" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:reload, [:default])

        engine.reload(:default)
      end
    end

    context "with multiple given scope" do
      it "runs all with the scope" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:reload, %i[default frontend])

        engine.reload(:default, :frontend)
      end
    end

    context "with multiple given scope as array" do
      it "runs all with the scope" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:reload, %i[default frontend])

        engine.reload(%i[default frontend])
      end
    end
  end

  describe "#run_all" do
    before do
      engine.setup
    end

    it "clears the screen and prints information message" do
      expect(Guard::UI).to receive(:clear)
      expect(Guard::UI).to receive(:action_with_scopes).with("Run", engine.session.scope_titles({}))

      engine.run_all
    end

    context "with an empty scope" do
      it "runs all" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:run_all, [])

        engine.run_all
      end
    end

    context "with a given scope" do
      it "runs all with the scope" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:run_all, [:default])

        engine.run_all(:default)
      end
    end

    context "with multiple given scope" do
      it "runs all with the scope" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:run_all, %i[default frontend])

        engine.run_all(:default, :frontend)
      end
    end

    context "with multiple given scope as array" do
      it "runs all with the scope" do
        expect(engine.__send__(:_runner)).to receive(:run).with(:run_all, %i[default frontend])

        engine.run_all(%i[default frontend])
      end
    end
  end

  describe "#pause" do
    context "when unpaused" do
      before do
        allow(engine).to receive(:_listener).and_return(listener)
        allow(listener).to receive(:paused?) { false }
      end

      [:toggle, nil, :paused].each do |mode|
        context "with #{mode.inspect}" do
          before do
            allow(listener).to receive(:pause)
          end

          it "pauses" do
            expect(listener).to receive(:pause)

            engine.pause(mode)
          end

          it "shows a message" do
            expected = /File event handling has been paused/
            expect(Guard::UI).to receive(:info).with(expected)

            engine.pause(mode)
          end
        end
      end

      context "with :unpaused" do
        it "does nothing" do
          expect(listener).to_not receive(:start)
          expect(listener).to_not receive(:pause)

          engine.pause(:unpaused)
        end
      end

      context "with invalid parameter" do
        it "raises an ArgumentError" do
          expect { engine.pause(:invalid) }
            .to raise_error(ArgumentError, "invalid mode: :invalid")
        end
      end
    end

    context "when already paused" do
      before do
        allow(engine).to receive(:_listener).and_return(listener)
        allow(listener).to receive(:paused?) { true }
      end

      [:toggle, nil, :unpaused].each do |mode|
        context "with #{mode.inspect}" do
          before do
            allow(listener).to receive(:start)
          end

          it "unpauses" do
            expect(listener).to receive(:start)

            engine.pause(mode)
          end

          it "shows a message" do
            expected = /File event handling has been resumed/
            expect(Guard::UI).to receive(:info).with(expected)

            engine.pause(mode)
          end
        end
      end

      context "with :paused" do
        it "does nothing" do
          expect(listener).to_not receive(:start)
          expect(listener).to_not receive(:pause)
          engine.pause(:paused)
        end
      end

      context "with invalid parameter" do
        it "raises an ArgumentError" do
          expect { engine.pause(:invalid) }
            .to raise_error(ArgumentError, "invalid mode: :invalid")
        end
      end
    end
  end

  describe "#show" do
    let(:dsl_describer) { instance_double("Guard::DslDescriber") }

    before do
      allow(Guard::DslDescriber).to receive(:new).with(engine)
                                                 .and_return(dsl_describer)
    end

    it "shows list of plugins" do
      expect(dsl_describer).to receive(:show)

      engine.show
    end
  end

  describe "._relative_pathname" do
    subject { engine.__send__(:_relative_pathname, raw_path) }

    let(:pwd) { Pathname("/project") }

    before { allow(Pathname).to receive(:pwd).and_return(pwd) }

    context "with file in project directory" do
      let(:raw_path) { "/project/foo" }
      it { is_expected.to eq(Pathname("foo")) }
    end

    context "with file within project" do
      let(:raw_path) { "/project/spec/models/foo_spec.rb" }
      it { is_expected.to eq(Pathname("spec/models/foo_spec.rb")) }
    end

    context "with file in parent directory" do
      let(:raw_path) { "/foo" }
      it { is_expected.to eq(Pathname("../foo")) }
    end

    context "with file on another drive (e.g. Windows)" do
      let(:raw_path) { "d:/project/foo" }
      let(:pathname) { instance_double(Pathname) }

      before do
        allow_any_instance_of(Pathname).to receive(:relative_path_from)
          .with(pwd).and_raise(ArgumentError)
      end

      it { is_expected.to eq(Pathname.new("d:/project/foo")) }
    end
  end
end
