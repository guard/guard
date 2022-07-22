# frozen_string_literal: true

require "guard/interactor"

RSpec.describe Guard::Interactor, :stub_ui do
  include_context "with engine"

  let(:interactive) { true }

  subject { described_class.new(engine, interactive) }

  let!(:pry_interactor) { instance_double("Guard::Jobs::PryWrapper", foreground: true, background: true) }
  let!(:sleep_interactor) { instance_double("Guard::Jobs::Sleep", foreground: true, background: true) }

  before do
    allow(Guard::Interactor).to receive(:new).and_call_original
    allow(Guard::Jobs::PryWrapper).to receive(:new).with(engine, {}).and_return(pry_interactor)
    allow(Guard::Jobs::Sleep).to receive(:new).with(engine, {}).and_return(sleep_interactor)
  end

  describe "#enabled & #enabled=" do
    it "returns true by default" do
      expect(subject).to be_interactive
    end

    context "interactor not enabled" do
      before { subject.interactive = false }

      it "returns false" do
        expect(subject).to_not be_interactive
      end
    end
  end

  describe "#options & #options=" do
    before { subject.options = nil }

    it "returns {} by default" do
      expect(subject.options).to eq({})
    end

    context "options set to { foo: :bar }" do
      before { subject.options = { foo: :bar } }

      it "returns { foo: :bar }" do
        expect(subject.options).to eq(foo: :bar)
      end
    end

    context "options set after interactor is instantiated" do
      it "set the options and initialize a new interactor job" do
        subject.foreground

        expect(Guard::Jobs::PryWrapper).to receive(:new).with(engine, foo: :bar).and_return(pry_interactor)

        subject.options = { foo: :bar }
        subject.foreground
      end
    end
  end

  context "when enabled" do
    before { subject.interactive = true }

    describe "#foreground" do
      it "starts Pry" do
        expect(pry_interactor).to receive(:foreground)

        subject.foreground
      end
    end

    describe "#background" do
      it "hides Pry" do
        # Eager-init the job
        subject.foreground

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
    before { subject.interactive = false }

    describe "#foreground" do
      it "sleeps" do
        expect(sleep_interactor).to receive(:foreground)

        subject.foreground
      end
    end

    describe "#background" do
      it "wakes up from sleep" do
        # Eager-init the job
        subject.foreground

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
    before do
      subject.interactive = dsl_enabled
    end

    context "when enabled from the DSL" do
      let(:dsl_enabled) { true }

      context "when enabled from the commandline" do
        let(:interactive) { true }

        it "uses only pry" do
          expect(Guard::Jobs::PryWrapper).to receive(:new)
          expect(Guard::Jobs::Sleep).to_not receive(:new)

          subject.foreground
        end

        it { is_expected.to be_interactive }
      end

      context "when disabled from the commandline" do
        let(:interactive) { false }

        it "uses only sleeper" do
          expect(Guard::Jobs::PryWrapper).to receive(:new)
          expect(Guard::Jobs::Sleep).to_not receive(:new)

          subject.foreground
        end

        it { is_expected.to be_interactive }
      end
    end

    context "when disabled from the DSL" do
      let(:dsl_enabled) { false }

      context "when enabled from the commandline" do
        it "uses only sleeper" do
          expect(Guard::Jobs::PryWrapper).to_not receive(:new)
          expect(Guard::Jobs::Sleep).to receive(:new)

          subject.foreground
        end

        it { is_expected.to_not be_interactive }
      end

      context "when disabled from the commandline" do
        let(:interactive) { false }

        it "uses only sleeper" do
          expect(Guard::Jobs::PryWrapper).to_not receive(:new)
          expect(Guard::Jobs::Sleep).to receive(:new)

          subject.foreground
        end

        it { is_expected.to_not be_interactive }
      end
    end
  end

  context "when first enabled, then disabled" do
    it "uses only sleeper" do
      expect(Guard::Jobs::PryWrapper).to receive(:new)

      subject.foreground
      subject.interactive = false

      expect(Guard::Jobs::Sleep).to receive(:new)

      subject.foreground
    end
  end

  context "when first disabled, then enabled" do
    let(:interactive) { false }

    it "uses only sleeper" do
      expect(Guard::Jobs::Sleep).to receive(:new)

      subject.foreground
      subject.interactive = true

      expect(Guard::Jobs::PryWrapper).to receive(:new)

      subject.foreground
    end
  end
end
