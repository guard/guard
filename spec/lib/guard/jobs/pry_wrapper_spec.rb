require "spec_helper"

require "guard/jobs/pry_wrapper"

describe Guard::Jobs::PryWrapper do
  subject { described_class.new({}) }
  let(:listener) { instance_double(Listen::Listener) }
  let(:pry_config) { double("pry_config") }
  let(:pry_history) { double("pry_history") }
  let(:pry_commands) { double("pry_commands") }
  let(:pry_hooks) { double("pry_hooks") }

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
    allow(Guard::Sheller).to receive(:run).with(*%w(hash stty)) { false }
  end

  describe "#foreground" do

    before do
      allow(Pry).to receive(:start) do
        # sleep for a long time (anything > 0.6)
        sleep 2
      end
    end

    after do
      subject.background
    end

    it "waits for Pry thread to finish" do
      was_alive = false

      Thread.new do
        sleep 0.1
        was_alive = subject.send(:thread).alive?
        subject.background
      end

      subject.foreground # blocks
      expect(was_alive).to be
    end

    it "prevents the Pry thread from being killed too quickly" do
      start = Time.now.to_f

      Thread.new do
        sleep 0.1
        subject.background
      end

      subject.foreground # blocks
      killed_moment = Time.now.to_f

      expect(killed_moment - start).to be > 0.5
    end

    it "return :stopped when brought into background" do
      Thread.new do
        sleep 0.1
        subject.background
      end

      expect(subject.foreground).to be(:stopped)
    end

  end

  describe "#background" do
    before do
      allow(Pry).to receive(:start) do
        # 0.5 is enough for Pry, so we use 0.4
        sleep 0.4
      end
    end

    it "kills the Pry thread" do
      subject.foreground
      sleep 1 # give Pry 0.5 sec to boot
      subject.background
      sleep 0.25 # to let Pry get killed asynchronously

      expect(subject.send(:thread)).to be_nil
    end
  end

  describe "#_prompt(ending_char)" do
    let(:prompt) { subject.send(:_prompt, ">") }

    before do
      allow(Guard::Sheller).to receive(:run).with(*%w(hash stty)) { false }
      allow(::Guard).to receive(:scope).and_return({})
      allow(::Guard.scope).to receive(:[]).with(:plugins).and_return([])
      allow(::Guard.scope).to receive(:[]).with(:groups).and_return([])

      allow(listener).to receive(:paused?).and_return(false)

      expect(Pry).to receive(:view_clip).and_return("main")
    end

    let(:pry) { instance_double(Pry, input_array: []) }

    context "Guard is not paused" do
      it 'displays "guard"' do
        expect(prompt.call(double, 0, pry)).
          to eq "[0] guard(main)> "
      end
    end

    context "Guard is paused" do
      before do
        allow(listener).to receive(:paused?).and_return(true)
      end

      it 'displays "pause"' do
        expect(prompt.call(double, 0, pry)).
          to eq "[0] pause(main)> "
      end
    end

    context "with a groups scope" do
      before do
        allow(::Guard.scope).to receive(:[]).with(:groups).
          and_return([double(title: "Backend"), double(title: "Frontend")])
      end

      it "displays the group scope title in the prompt" do
        expect(prompt.call(double, 0, pry)).
          to eq "[0] Backend,Frontend guard(main)> "

      end
    end

    context "with a plugins scope" do

      before do
        allow(::Guard.scope).to receive(:[]).with(:plugins).
          and_return([double(title: "RSpec"), double(title: "Ronn")])
      end

      it "displays the group scope title in the prompt" do
        result = prompt.call(double, 0, pry)
        expect(result).to eq "[0] RSpec,Ronn guard(main)> "
      end
    end

  end
end
