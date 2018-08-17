# frozen_string_literal: true
require 'guard/jobs/pry_wrapper'

RSpec.describe Guard::Jobs::PryWrapper do
  subject { described_class.new({}) }
  let(:listener) { instance_double('Listen::Listener') }
  let(:pry_config) { double('pry_config') }
  let(:pry_history) { double('pry_history') }
  let(:pry_commands) { double('pry_commands') }
  let(:pry_hooks) { double('pry_hooks') }
  let(:terminal_settings) { instance_double('Guard::Jobs::TerminalSettings') }

  let(:session) { instance_double('Guard::Internals::Session') }
  let(:plugins) { instance_double('Guard::Internals::Plugins') }
  let(:groups) { instance_double('Guard::Internals::Groups') }
  let(:state) { instance_double('Guard::Internals::State') }
  let(:scope) { instance_double('Guard::Internals::Scope') }

  before do
    # TODO: this are here to mock out Pry completely
    allow(pry_config).to receive(:prompt=)
    allow(pry_config).to receive(:should_load_rc=)
    allow(pry_config).to receive(:should_load_local_rc=)
    allow(pry_config).to receive(:hooks).and_return(pry_hooks)
    allow(pry_config).to receive(:history).and_return(pry_history)
    allow(pry_config).to receive(:commands).and_return(pry_commands)
    allow(pry_history).to receive(:file=)
    allow(pry_commands).to receive(:alias_command)
    allow(pry_commands).to receive(:create_command)
    allow(pry_commands).to receive(:command)
    allow(pry_commands).to receive(:block_command)
    allow(pry_hooks).to receive(:add_hook)

    allow(Guard).to receive(:listener).and_return(listener)
    allow(Pry).to receive(:config).and_return(pry_config)
    allow(Shellany::Sheller).to receive(:run).with(*%w(hash stty)) { false }

    allow(groups).to receive(:all).and_return([])
    allow(session).to receive(:groups).and_return(groups)

    allow(plugins).to receive(:all).and_return([])
    allow(session).to receive(:plugins).and_return(plugins)
    allow(state).to receive(:session).and_return(session)
    allow(state).to receive(:scope).and_return(scope)
    allow(Guard).to receive(:state).and_return(state)

    allow(Guard::Commands::All).to receive(:import)
    allow(Guard::Commands::Change).to receive(:import)
    allow(Guard::Commands::Reload).to receive(:import)
    allow(Guard::Commands::Pause).to receive(:import)
    allow(Guard::Commands::Notification).to receive(:import)
    allow(Guard::Commands::Show).to receive(:import)
    allow(Guard::Commands::Scope).to receive(:import)

    allow(Guard::Jobs::TerminalSettings).to receive(:new).
      and_return(terminal_settings)

    allow(terminal_settings).to receive(:configurable?).and_return(false)
    allow(terminal_settings).to receive(:save)
    allow(terminal_settings).to receive(:restore)
  end

  describe '#foreground' do
    before do
      allow(Pry).to receive(:start) do
        # sleep for a long time (anything > 0.6)
        sleep 2
      end
    end

    after do
      subject.background
    end

    it 'waits for Pry thread to finish' do
      was_alive = false

      Thread.new do
        sleep 0.1
        was_alive = subject.send(:thread).alive?
        subject.background
      end

      subject.foreground # blocks
      expect(was_alive).to be
    end

    it 'prevents the Pry thread from being killed too quickly' do
      start = Time.now.to_f

      Thread.new do
        sleep 0.1
        subject.background
      end

      subject.foreground # blocks
      killed_moment = Time.now.to_f

      expect(killed_moment - start).to be > 0.5
    end

    it 'return :stopped when brought into background' do
      Thread.new do
        sleep 0.1
        subject.background
      end

      expect(subject.foreground).to be(:stopped)
    end
  end

  describe '#background' do
    before do
      allow(Pry).to receive(:start) do
        # 0.5 is enough for Pry, so we use 0.4
        sleep 0.4
      end
    end

    it 'kills the Pry thread' do
      subject.foreground
      sleep 1 # give Pry 0.5 sec to boot
      subject.background
      sleep 0.25 # to let Pry get killed asynchronously

      expect(subject.send(:thread)).to be_nil
    end
  end

  describe '#_prompt(ending_char)' do
    let(:prompt) { subject.send(:_prompt, '>') }

    before do
      allow(Shellany::Sheller).to receive(:run).with(*%w(hash stty)) { false }
      allow(scope).to receive(:titles).and_return(['all'])

      allow(listener).to receive(:paused?).and_return(false)

      expect(Pry).to receive(:view_clip).and_return('main')
    end

    let(:pry) { instance_double(Pry, input_array: []) }

    context 'Guard is not paused' do
      it 'displays "guard"' do
        expect(prompt.call(double, 0, pry)).
          to eq '[0] guard(main)> '
      end
    end

    context 'Guard is paused' do
      before do
        allow(listener).to receive(:paused?).and_return(true)
      end

      it 'displays "pause"' do
        expect(prompt.call(double, 0, pry)).
          to eq '[0] pause(main)> '
      end
    end

    context 'with a groups scope' do
      before do
        allow(scope).to receive(:titles).and_return(%w(Backend Frontend))
      end

      it 'displays the group scope title in the prompt' do
        expect(prompt.call(double, 0, pry)).
          to eq '[0] Backend,Frontend guard(main)> '
      end
    end

    context 'with a plugins scope' do
      before do
        allow(scope).to receive(:titles).and_return(%w(RSpec Ronn))
      end

      it 'displays the group scope title in the prompt' do
        result = prompt.call(double, 0, pry)
        expect(result).to eq '[0] RSpec,Ronn guard(main)> '
      end
    end
  end
end
