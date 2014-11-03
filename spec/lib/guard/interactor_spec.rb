require "guard/plugin"

RSpec.describe Guard::Interactor do
  let(:pry_interactor) { double(Guard::Jobs::PryWrapper) }
  let(:sleep_interactor) { double(Guard::Jobs::Sleep) }

  before do
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

  describe ".convert_scope" do
    before do
      allow(::Guard::Notifier).to receive(:turn_on) { nil }
      allow(Listen).to receive(:to).with(Dir.pwd, {})

      stub_const "Guard::Foo", Class.new(Guard::Plugin)
      stub_const "Guard::Bar", Class.new(Guard::Plugin)

      guard = ::Guard

      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_plugin(:foo,  group: :backend)
      @bar_guard      = guard.add_plugin(:bar,  group: :frontend)
    end

    it "returns a group scope" do
      scopes, _ = Guard::Interactor.convert_scope %w(backend)
      expect(scopes).to eq(groups: [@backend_group], plugins: [])
      scopes, _ = Guard::Interactor.convert_scope %w(frontend)
      expect(scopes).to eq(groups: [@frontend_group], plugins: [])
    end

    it "returns a plugin scope" do
      scopes, _ = Guard::Interactor.convert_scope %w(foo)
      expect(scopes).to eq(plugins: [@foo_guard], groups: [])
      scopes, _ = Guard::Interactor.convert_scope %w(bar)
      expect(scopes).to eq(plugins: [@bar_guard], groups: [])
    end

    it "returns multiple group scopes" do
      scopes, _ = Guard::Interactor.convert_scope %w(backend frontend)
      expected = { groups: [@backend_group, @frontend_group], plugins: [] }
      expect(scopes).to eq(expected)
    end

    it "returns multiple plugin scopes" do
      scopes, _ = Guard::Interactor.convert_scope %w(foo bar)
      expect(scopes).to eq(plugins: [@foo_guard, @bar_guard], groups: [])
    end

    it "returns a plugin and group scope" do
      scopes, _ = Guard::Interactor.convert_scope %w(foo backend)
      expect(scopes).to eq(plugins: [@foo_guard], groups: [@backend_group])
    end

    it "returns the unkown scopes" do
      _, unkown = Guard::Interactor.convert_scope %w(unkown scope)
      expect(unkown).to eq %w(unkown scope)
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

end
