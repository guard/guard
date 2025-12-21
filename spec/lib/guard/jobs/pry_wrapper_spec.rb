# frozen_string_literal: true

require "guard/jobs/pry_wrapper"

RSpec.describe Guard::Jobs::PryWrapper, :stub_ui do
  include_context "with engine"

  let(:pry_hooks) { double("pry_hooks", add_hook: true) }
  let(:pry_config) do
    double("pry_config", "history_file=" => true, command_prefix: true, "prompt=" => true, "should_load_rc=" => true,
                         "should_load_local_rc=" => true, hooks: pry_hooks)
  end
  let(:pry_history) { double("pry_history") }
  let(:pry_commands) do
    double("pry_commands", alias_command: true, create_command: true, command: true, block_command: true)
  end
  let(:terminal_settings) { instance_double("Guard::Jobs::TerminalSettings") }

  subject { described_class.new(engine) }

  before do
    allow(Pry).to receive(:config).and_return(pry_config)
    allow(Pry).to receive(:commands).and_return(pry_commands)

    allow(Guard::Commands::All).to receive(:import)
    allow(Guard::Commands::Change).to receive(:import)
    allow(Guard::Commands::Reload).to receive(:import)
    allow(Guard::Commands::Pause).to receive(:import)
    allow(Guard::Commands::Notification).to receive(:import)
    allow(Guard::Commands::Show).to receive(:import)
    allow(Guard::Commands::Scope).to receive(:import)

    allow(Guard::Jobs::TerminalSettings).to receive(:new)
      .and_return(terminal_settings)

    allow(terminal_settings).to receive(:configurable?).and_return(false)
    allow(terminal_settings).to receive(:save)
    allow(terminal_settings).to receive(:restore)

    engine.setup
  end

  describe "#_setup" do
    context "Guard is using Pry >= 0.13" do
      it "calls Pry.config.history_file=" do
        expect(pry_config).to receive(:history_file=)

        subject
      end
    end

    context "Guard is using Pry < 0.13" do
      let(:pry_config) do
        double("pry_config", "history" => true, command_prefix: true, "prompt=" => true, "should_load_rc=" => true,
                             "should_load_local_rc=" => true, hooks: pry_hooks)
      end

      it "calls Pry.config.history.file=" do
        expect(pry_config).to receive(:history).and_return(pry_history)
        expect(pry_history).to receive(:file=)

        subject
      end
    end
  end

  describe "#foreground" do
    let(:pry_started) { Queue.new }
    let(:pry_can_finish) { Queue.new }

    before do
      allow(Pry).to receive(:start) do
        pry_started.push(true)
        pry_can_finish.pop
      end
    end

    after do
      pry_can_finish.push(true) rescue nil
      subject.background
    end

    it "waits for Pry thread to finish" do
      was_running = false

      foreground_thread = Thread.new do
        subject.foreground
      end

      pry_started.pop  # Wait for Pry to start
      was_running = subject.instance_variable_get(:@pry_thread)&.alive?
      subject.background
      pry_can_finish.push(true)

      foreground_thread.join
      expect(was_running).to be true
    end

    it "returns :continue when brought into background" do
      result = nil

      foreground_thread = Thread.new do
        result = subject.foreground
      end

      pry_started.pop
      subject.background
      pry_can_finish.push(true)

      foreground_thread.join
      expect(result).to be(:continue)
    end
  end

  describe "#background" do
    let(:pry_started) { Queue.new }
    let(:pry_can_finish) { Queue.new }

    before do
      allow(Pry).to receive(:start) do
        pry_started.push(true)
        pry_can_finish.pop
      end
    end

    it "kills the Pry thread" do
      foreground_thread = Thread.new do
        subject.foreground
      end

      pry_started.pop
      subject.background
      pry_can_finish.push(true)

      foreground_thread.join

      expect(subject.instance_variable_get(:@pry_thread)).to be_nil
    end
  end

  describe "#_prompt(ending_char)" do
    let(:prompt) { subject.send(:_prompt, ">") }

    before do
      allow(Shellany::Sheller).to receive(:run).with("hash", "stty") { false }
      allow(engine).to receive(:paused?).and_return(false)
      allow(Pry).to receive(:view_clip).and_return("main")
    end

    context "Guard is using Pry >= 0.13" do
      let(:pry) { double("Pry", input_ring: []) }
      let(:pry_prompt) { double }

      it "calls Pry::Prompt.new" do
        expect(Pry::Prompt).to receive(:is_a?).with(Class).and_return(true)
        expect(Pry::Prompt).to receive(:new).with("Guard", "Guard Pry prompt", an_instance_of(Array)).and_return(pry_prompt)
        expect(pry_config).to receive(:prompt=).with(pry_prompt)

        subject
      end

      context "Guard is not paused" do
        it "displays 'guard'" do
          expect(prompt.call(double, 0, pry))
            .to eq "[0] guard(main)> "
        end
      end

      context "Guard is paused" do
        before do
          allow(engine).to receive(:paused?).and_return(true)
        end

        it "displays 'pause'" do
          expect(prompt.call(double, 0, pry))
            .to eq "[0] pause(main)> "
        end
      end

      context "with a groups scope" do
        before do
          allow(engine.session).to receive(:scope_titles).and_return(%w[Backend Frontend])
        end

        it "displays the group scope title in the prompt" do
          expect(prompt.call(double, 0, pry))
            .to eq "[0] Backend,Frontend guard(main)> "
        end
      end

      context "with a plugins scope" do
        before do
          allow(engine.session).to receive(:scope_titles).and_return(%w[RSpec Ronn])
        end

        it "displays the group scope title in the prompt" do
          result = prompt.call(double, 0, pry)
          expect(result).to eq "[0] RSpec,Ronn guard(main)> "
        end
      end
    end

    context "Guard is using Pry < 0.13" do
      let(:pry) { double("Pry", input_array: []) }

      it "does not call Pry::Prompt.new" do
        expect(Pry::Prompt).to receive(:is_a?).with(Class).and_return(false)
        expect(pry_config).to receive(:prompt=).with(an_instance_of(Array))

        subject
      end

      it "displays 'guard'" do
        expect(prompt.call(double, 0, pry))
          .to eq "[0] guard(main)> "
      end
    end
  end
end
