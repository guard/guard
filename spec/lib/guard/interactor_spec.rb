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
