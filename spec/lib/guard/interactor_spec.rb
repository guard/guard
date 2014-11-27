require "guard/interactor"

# TODO: this shouldn't be necessary
require "guard/jobs/pry_wrapper"
require "guard/jobs/sleep"

RSpec.describe Guard::Interactor do
  let!(:pry_interactor) { instance_double("Guard::Jobs::PryWrapper") }
  let!(:sleep_interactor) { instance_double("Guard::Jobs::Sleep") }
  let(:pry_class) { class_double("Guard::Jobs::PryWrapper") }
  let(:sleep_class) { class_double("Guard::Jobs::Sleep") }

  before do
    stub_const("Guard::Jobs::PryWrapper", pry_class)
    stub_const("Guard::Jobs::Sleep", sleep_class)

    allow(Guard::Jobs::PryWrapper).to receive(:new).and_return(pry_interactor)
    allow(Guard::Jobs::Sleep).to receive(:new).and_return(sleep_interactor)

    @interactor_enabled = described_class.enabled?
    described_class.enabled = nil
  end

  after { described_class.enabled = @interactor_enabled }

  describe ".enabled & .enabled=" do
    it "returns true by default" do
      expect(described_class).to be_enabled
    end

    context "interactor not enabled" do
      before { described_class.enabled = false }

      it "returns false" do
        expect(described_class).to_not be_enabled
      end
    end
  end

  describe ".options & .options=" do
    before { described_class.options = nil }

    it "returns {} by default" do
      expect(described_class.options).to eq({})
    end

    context "options set to { foo: :bar }" do
      before { described_class.options = { foo: :bar } }

      it "returns { foo: :bar }" do
        expect(described_class.options).to eq(foo: :bar)
      end
    end
  end

  # TODO: move to metadata class
  describe ".convert_scope" do
    let(:foo) { instance_double("Guard::Plugin", name: "foo") }
    let(:bar) { instance_double("Guard::Plugin", name: "bar") }
    let(:backend) { instance_double("Guard::Group", name: "backend") }
    let(:frontend) { instance_double("Guard::Group", name: "frontend") }

    let(:session) { instance_double("Guard::Internals::Session") }
    let(:groups) { instance_double("Guard::Internals::Groups") }
    let(:plugins) { instance_double("Guard::Internals::Plugins") }
    let(:state) { instance_double("Guard::Internals::State") }

    before do
      allow(Guard::Notifier).to receive(:turn_on) { nil }
      allow(Listen).to receive(:to).with(Dir.pwd, {})

      stub_const "Guard::Foo", class_double("Guard::Plugin")
      stub_const "Guard::Bar", class_double("Guard::Plugin")

      allow(state).to receive(:session).and_return(session)
      allow(Guard).to receive(:state).and_return(state)

      allow(session).to receive(:plugins).and_return(plugins)
      allow(session).to receive(:groups).and_return(groups)

      allow(plugins).to receive(:all).with("backend").and_return([])
      allow(plugins).to receive(:all).with("frontend").and_return([])
      allow(plugins).to receive(:all).with("foo").and_return([foo])
      allow(plugins).to receive(:all).with("bar").and_return([bar])
      allow(plugins).to receive(:all).with("unknown").and_return([])
      allow(plugins).to receive(:all).with("scope").and_return([])

      allow(groups).to receive(:all).with("backend").and_return([backend])
      allow(groups).to receive(:all).with("frontend").and_return([frontend])
      allow(groups).to receive(:all).with("unknown").and_return([])
      allow(groups).to receive(:all).with("scope").and_return([])
    end

    it "returns a group scope" do
      scopes, _ = Guard::Interactor.convert_scope %w(backend)
      expect(scopes).to eq(groups: [backend], plugins: [])
      scopes, _ = Guard::Interactor.convert_scope %w(frontend)
      expect(scopes).to eq(groups: [frontend], plugins: [])
    end

    it "returns a plugin scope" do
      scopes, _ = Guard::Interactor.convert_scope %w(foo)
      expect(scopes).to eq(plugins: [foo], groups: [])
      scopes, _ = Guard::Interactor.convert_scope %w(bar)
      expect(scopes).to eq(plugins: [bar], groups: [])
    end

    it "returns multiple group scopes" do
      scopes, _ = Guard::Interactor.convert_scope %w(backend frontend)
      expected = { groups: [backend, frontend], plugins: [] }
      expect(scopes).to eq(expected)
    end

    it "returns multiple plugin scopes" do
      scopes, _ = Guard::Interactor.convert_scope %w(foo bar)
      expect(scopes).to eq(plugins: [foo, bar], groups: [])
    end

    it "returns a plugin and group scope" do
      scopes, _ = Guard::Interactor.convert_scope %w(foo backend)
      expect(scopes).to eq(plugins: [foo], groups: [backend])
    end

    it "returns the unkown scopes" do
      _, unknown = Guard::Interactor.convert_scope %w(unknown scope)
      expect(unknown).to eq %w(unknown scope)
    end
  end

  context "when enabled" do
    before { described_class.enabled = true }

    describe "#foreground" do
      it "starts Pry" do
        expect(pry_interactor).to receive(:foreground)
        subject.foreground
      end
    end

    describe "#background" do
      it "hides Pry" do
        expect(pry_interactor).to receive(:background)
        subject.background
      end
    end

    describe "#handle_interrupt" do
      it "interrupts Pry" do
        expect(pry_interactor).to receive(:handle_interrupt)
        subject.handle_interrupt
      end
    end
  end

  context "when disabled" do
    before { described_class.enabled = false }

    describe "#foreground" do
      it "sleeps" do
        expect(sleep_interactor).to receive(:foreground)
        subject.foreground
      end
    end

    describe "#background" do
      it "wakes up from sleep" do
        expect(sleep_interactor).to receive(:background)
        subject.background
      end
    end

    describe "#handle_interrupt" do
      it "interrupts sleep" do
        expect(sleep_interactor).to receive(:handle_interrupt)
        subject.handle_interrupt
      end
    end
  end

  describe "job selection" do
    subject do
      Guard::Interactor.new(no_interactions)
      Guard::Interactor
    end

    before do
      Guard::Interactor.enabled = dsl_enabled
    end

    context "when enabled from the DSL" do
      let(:dsl_enabled) { true }

      context "when enabled from the commandline" do
        let(:no_interactions) { false }
        it "uses only pry" do
          expect(pry_class).to receive(:new)
          expect(sleep_class).to_not receive(:new)
          subject
        end
        it { is_expected.to be_enabled }
      end

      context "when disabled from the commandline" do
        let(:no_interactions) { true }
        it "uses only sleeper" do
          expect(pry_class).to_not receive(:new)
          expect(sleep_class).to receive(:new)
          subject
        end

        # TODO: this is both a useless case and incorrect value
        it { is_expected.to be_enabled }
      end
    end

    context "when disabled from the DSL" do
      let(:dsl_enabled) { false }

      context "when enabled from the commandline" do
        let(:no_interactions) { false }
        it "uses only sleeper" do
          expect(pry_class).to_not receive(:new)
          expect(sleep_class).to receive(:new)
          subject
        end
        it { is_expected.to_not be_enabled }
      end

      context "when disabled from the commandline" do
        let(:no_interactions) { true }
        it "uses only sleeper" do
          expect(pry_class).to_not receive(:new)
          expect(sleep_class).to receive(:new)
          subject
        end
        it { is_expected.to_not be_enabled }
      end
    end
  end
end
