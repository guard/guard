require "guard/notifier"

RSpec.describe Guard::Notifier do
  subject { described_class }

  # Use tmux as base, because it has both :turn_on and :turn_off
  %w(foo bar baz).each do |name|
    let(name.to_sym) do
      class_double(
        described_class::Tmux,
        name: name,
        title: name.capitalize,
        turn_on: nil,
        turn_off: nil
      )
    end
  end

  let(:foo_object) { instance_double(described_class::Tmux) }
  let(:bar_object) { instance_double(described_class::Tmux) }

  class FakeEnvironment < Guard::Internals::Environment
    def notify?
    end

    # TODO: shorten? (using namespace)
    def notify_pid=(_value)
    end

    def notify_pid
    end

    def notify_active=(_value)
    end

    def notify_active?
    end
  end

  let(:env) { instance_double(FakeEnvironment) }
  let(:detected) { instance_double(described_class::Detected) }

  before do
    Guard::Notifier.instance_variables.each do |var|
      Guard::Notifier.instance_variable_set(var, nil)
    end

    allow(Guard::Internals::Environment).to receive(:new).with("GUARD").
      and_return(env)

    allow(env).to receive(:create_method).with(:notify?)
    allow(env).to receive(:create_method).with(:notify_active=)
    allow(env).to receive(:create_method).with(:notify_active?)
    allow(env).to receive(:create_method).with(:notify_pid)
    allow(env).to receive(:create_method).with(:notify_pid=)

    # DEFAULTS FOR TESTS
    allow(env).to receive(:notify?).and_return(true)
    allow(env).to receive(:notify_active?).and_return(false)
    allow(env).to receive(:notify_active=)
    allow(env).to receive(:notify_pid).and_return($$)
    allow(env).to receive(:notify_pid=).with($$)

    allow(described_class::Detected).to receive(:new).
      with(described_class::SUPPORTED).and_return(detected)

    allow(detected).to receive(:add)
    allow(detected).to receive(:reset)
    allow(detected).to receive(:detect)
    allow(detected).to receive(:available).and_return([[foo, {}]])
  end

  after do
    # This is ok, because it shows singletons are NOT ok
    described_class.instance_variable_set(:@detected, nil)
  end

  describe ".connect" do
    before do
      allow(env).to receive(:notify?).and_return(env_enabled)
    end

    context "when enabled with environment" do
      let(:env_enabled) { true }

      context "when enabled with options" do
        let(:options) { { notify: true } }
        it "assigns a pid" do
          expect(env).to receive(:notify_pid=).with($$)
          subject.connect(options)
        end
      end

      context "when disabled with options" do
        let(:options) { { notify: false } }
        it "assigns a pid anyway" do
          expect(env).to receive(:notify_pid=).with($$)
          subject.connect(options)
        end
      end
    end

    context "when disabled with environment" do
      let(:env_enabled) { false }
    end
  end

  describe ".disconnect" do
    before do
      allow(env).to receive(:notify_pid=)
      subject.connect
    end

    it "resets detector" do
      expect(detected).to receive(:reset)
      subject.disconnect
    end

    it "reset the pid env var" do
      expect(env).to receive(:notify_pid=).with(nil)
      subject.disconnect
    end
  end

  describe ".turn_on" do
    let(:options) { {} }

    before do
      allow(detected).to receive(:available).and_return(available)

      subject.connect(notify: true)
      allow(env).to receive(:notify_active?).and_return(true)
      subject.turn_off
      allow(env).to receive(:notify_active?).and_return(false)
    end

    context "with available notifiers" do
      let(:available) { [[foo, { color: true }]] }

      context "when a child process" do
        before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
        it { expect { subject.turn_on }.to raise_error(/Only notify()/) }
      end

      context "without silent option" do
        let(:options) { { silent: false } }
        it "shows the used notifications" do
          expect(Guard::UI).to receive(:info).
            with "Guard is using Foo to send notifications."
          subject.turn_on(options)
        end
      end

      context "with silent option" do
        let(:options) { { silent: true } }
        it "does not show activated notifiers" do
          expect(Guard::UI).to_not receive(:info)
          subject.turn_on(options)
        end
      end
    end

    context "without available notifiers" do
      let(:available) { [] }
      it "sets mode to active" do
        expect(env).to receive(:notify_active=).with(true)
        subject.turn_on(options)
      end
    end
  end

  describe ".turn_off" do
    before do
      allow(env).to receive(:notify?).and_return(true)

      allow(detected).to receive(:available).
        and_return(available)
    end

    context "with no available notifiers" do
      let(:available) { [] }
      it "is not active" do
        subject.connect
        expect(subject).to_not be_active
      end
    end

    context "with available notifiers" do
      let(:available) { [[foo, {}]] }

      before do
        subject.connect(notify: true)
      end

      context "when a child process" do
        before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
        it { expect { subject.turn_off }.to raise_error(/Only notify()/) }
      end

      it "turns off each notifier" do
        allow(env).to receive(:notify_active?).and_return(true)
        expect(foo).to receive(:turn_off)
        subject.turn_off
      end
    end
  end

  describe "toggle_notification" do
    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:exist?).and_call_original
      allow(::Guard::UI).to receive(:info)
      allow(env).to receive(:notify_pid).and_return($$)

      subject.connect(notify: true)
    end

    context "with available notifiers" do
      context "when currently on" do
        it "suspends notifications" do
          subject.toggle
          expect(subject).to_not be_active
        end
      end

      context "when currently off" do
        before do
          allow(env).to receive(:notify_active?).and_return(false)
        end

        it "resumes notifications" do
          expect(env).to receive(:notify_active=).with(true)
          subject.toggle
        end
      end
    end
  end

  describe ".enabled?" do
    before do
      allow(env).to receive(:notify?).and_return(enabled)
    end

    context "when enabled" do
      let(:enabled) { true }
      it { is_expected.to be_enabled }
    end

    context "when disabled" do
      let(:enabled) { false }
      it { is_expected.not_to be_enabled }
    end
  end

  describe ".add" do
    before do
      allow(detected).to receive(:available).and_return([])
      allow(env).to receive(:notify?).and_return(enabled)
    end

    context "when child process" do
      let(:enabled) { true }
      before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
      it { expect { subject.add(:foo) }.to raise_error(/Only notify()/) }
    end

    context "when not connected" do
      context "when disabled" do
        let(:enabled) { false }

        it "does not add anything" do
          expect(detected).to_not receive(:add)
          subject.add(:foo)
        end
      end

      context "when enabled" do
        let(:enabled) { true }

        context "when supported" do
          let(:name) { foo }

          context "when available" do
            # TODO: this is not necessary
            before { allow(foo).to receive(:available?).and_return(true) }

            it "adds the notifier to the notifications" do
              expect(detected).to receive(:add).with(:foo, param: 1)
              subject.add_notifier(:foo, param: 1)
            end
          end
        end
      end
    end

    context "when connected" do
      before do
        allow(env).to receive(:notify?).and_return(enabled)
        subject.connect(notify: true)
      end

      context "when disabled" do
        let(:enabled) { false }

        it "does not add anything" do
          expect(detected).to_not receive(:add)
          subject.add_notifier(:foo)
        end
      end

      context "when enabled" do
        let(:enabled) { true }

        context "when :off" do
          it "turns off the notifier" do
            subject.add_notifier(:off)
            expect(subject).to_not be_active
          end
        end

        context "when supported" do
          let(:name) { foo }

          context "when available" do
            before { allow(foo).to receive(:available?).and_return(true) }

            it "adds the notifier to the notifications" do
              expect(detected).to receive(:add).
                with(:foo, param: 1)

              subject.add_notifier(:foo, param: 1)
            end
          end
        end
      end
    end
  end

  describe ".notify" do
    context "with multiple notifiers" do
      before do
        allow(detected).to receive(:available).
          and_return([[foo, { color: true }], [bar, {}]])

        allow(foo).to receive(:new).with(color: true).and_return(foo_object)
        allow(bar).to receive(:new).with({}).and_return(bar_object)
        allow(env).to receive(:notify?).and_return(enabled)
      end

      # TODO: deprecate
      context "when not connected" do
        let(:enabled) { true }

        before do
          allow(env).to receive(:notify_active?).and_return(false)
        end

        context "when a child process" do
          before { allow(env).to receive(:notify_pid).and_return($$ + 100) }

          before do
            allow(foo_object).to receive(:notify)
            allow(bar_object).to receive(:notify)
          end

          it "sends notifications" do
            expect(foo_object).to receive(:notify).with("Hello", foo: "bar")
            expect(bar_object).to receive(:notify).with("Hello", foo: "bar")
            subject.notify("Hello", foo: "bar")
          end

          it "shows a deprecation message" do
            expect(Guard::UI).to receive(:deprecation).
              with(/Notifier.notify\(\) without a prior Notifier.connect/)

            subject.notify("Hello", foo: "bar")
          end
        end
      end

      context "when connected" do
        before do
          subject.connect(notify: enabled)
          allow(env).to receive(:notify_active?).and_return(enabled)
        end

        context "when enabled" do
          let(:enabled) { true }

          it "sends notifications" do
            expect(foo_object).to receive(:notify).with("Hello", foo: "bar")
            expect(bar_object).to receive(:notify).with("Hello", foo: "bar")
            subject.notify("Hello", foo: "bar")
          end

          context "when a child process" do
            before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
            it "sends notifications" do
              expect(foo_object).to receive(:notify).with("Hello", foo: "bar")
              expect(bar_object).to receive(:notify).with("Hello", foo: "bar")
              subject.notify("Hello", foo: "bar")
            end
          end
        end

        context "when disabled" do
          let(:enabled) { false }

          it "does not send notifications" do
            expect(foo_object).to_not receive(:notify)
            expect(bar_object).to_not receive(:notify)
            subject.notify("Hi to everyone")
          end

          context "when a child process" do
            before { allow(env).to receive(:notify_pid).and_return($$ + 100) }
            it "sends notifications" do
              expect(foo_object).to_not receive(:notify)
              expect(bar_object).to_not receive(:notify)
              subject.notify("Hello", foo: "bar")
            end
          end
        end
      end
    end
  end

  describe ".notifiers" do
    context "when connected" do
      before do
        subject.connect(notify: true)
        allow(env).to receive(:notify_active?).and_return(true)
        allow(detected).to receive(:available).and_return(available)
      end

      context "with available notifiers" do
        let(:available) { [[foo, { color: true }], [baz, {}]] }
        it "returns a list of available notifier info" do
          expect(subject.notifiers).to eq(
            [
              { name: "foo", options: { color: true } },
              { name: "baz", options: {} },
            ]
          )
        end
      end
    end
  end
end
