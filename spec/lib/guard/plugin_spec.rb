# frozen_string_literal: true

require "guard/plugin"

RSpec.describe Guard::Plugin, :stub_ui do
  include_context "with engine"

  subject { described_class.new(engine: engine) }

  describe "#initialize" do
    context "without an engine given" do
      it "raises an exception" do
        expect { described_class.new }.to raise_error(described_class::NoEngineGiven)
      end
    end

    it "assigns the defined watchers" do
      watchers = [double("foo")]

      expect(described_class.new(engine: engine, watchers: watchers).watchers).to eq watchers
    end

    it "assigns the defined options" do
      options = { a: 1, b: 2 }

      expect(described_class.new(engine: engine, **options).options).to eq options
    end

    context "with a group in the options" do
      it "assigns the given group" do
        group = described_class.new(engine: engine, group: :test).group

        expect(group).to match a_kind_of(Guard::Group)
        expect(group.name).to eq(:test)
      end
    end

    context "without a group in the options" do
      it "assigns a default group" do
        group = described_class.new(engine: engine).group

        expect(group).to match a_kind_of(Guard::Group)
        expect(group.name).to eq(:default)
      end
    end

    context "with a callback" do
      it "adds the callback" do
        block1 = instance_double(Proc)
        block2 = instance_double(Proc)
        callbacks = [
          { events: [:start_begin], listener: block1 },
          { events: [:start_end], listener: block2 }
        ]
        plugin = described_class.new(engine: engine, callbacks: callbacks)

        expect(Guard::Plugin.callbacks[[plugin, :start_begin]]).to eq([block1])
        expect(Guard::Plugin.callbacks[[plugin, :start_end]]).to eq([block2])
      end
    end
  end

  context "with a specific plugin" do
    describe "class methods" do
      subject { Guard::Dummy }

      describe ".non_namespaced_classname" do
        it "remove the Guard:: namespace" do
          expect(subject.non_namespaced_classname).to eq "Dummy"
        end
      end

      describe ".non_namespaced_name" do
        it "remove the Guard:: namespace and downcase" do
          expect(subject.non_namespaced_name).to eq "dummy"
        end
      end

      describe ".template" do
        before do
          allow(File).to receive(:read)
        end

        it "reads the default template" do
          expect(File).to receive(:read)
            .with("/guard-dummy/lib/guard/dummy/templates/Guardfile") { true }

          subject.template("/guard-dummy")
        end
      end
    end

    describe "instance methods" do
      subject { Guard::Dummy.new(engine: engine) }

      describe "#name" do
        it "outputs the short plugin name" do
          expect(subject.name).to eq "dummy"
        end
      end

      describe "#title" do
        it "outputs the plugin title" do
          expect(subject.title).to eq "Dummy"
        end
      end

      describe "#to_s" do
        it "output the short plugin name" do
          expect(subject.to_s)
            .to match(/#<Guard::Dummy:\d+ @name=dummy .*>/)
        end
      end
    end
  end

  let(:listener) { instance_double(Proc, call: nil) }

  describe ".add_callback" do
    let(:foo) { double("foo plugin") }

    it "can add a run_on_modifications callback" do
      described_class.add_callback(
        listener,
        foo,
        :run_on_modifications_begin
      )

      result = described_class.callbacks[[foo, :run_on_modifications_begin]]
      expect(result).to include(listener)
    end

    it "can add multiple callbacks" do
      described_class.add_callback(listener, foo, %i[event1 event2])

      result = described_class.callbacks[[foo, :event1]]
      expect(result).to include(listener)

      result = described_class.callbacks[[foo, :event2]]
      expect(result).to include(listener)
    end
  end

  describe ".notify" do
    let(:foo) { double("foo plugin") }
    let(:bar) { double("bar plugin") }

    before do
      described_class.add_callback(listener, foo, :start_begin)
    end

    it "sends :call to the given Guard class's start_begin callback" do
      expect(listener).to receive(:call).with(foo, :start_begin, "args")
      described_class.notify(foo, :start_begin, "args")
    end

    it "sends :call to the given Guard class's start_begin callback" do
      expect(listener).to receive(:call).with(foo, :start_begin, "args")
      described_class.notify(foo, :start_begin, "args")
    end

    it "runs only the given callbacks" do
      listener2 = double("listener2")
      described_class.add_callback(listener2, foo, :start_end)
      expect(listener2).to_not receive(:call).with(foo, :start_end)
      described_class.notify(foo, :start_begin)
    end

    it "runs callbacks only for the guard given" do
      described_class.add_callback(listener, bar, :start_begin)
      expect(listener).to_not receive(:call).with(bar, :start_begin)
      described_class.notify(foo, :start_begin)
    end
  end

  describe "#hook" do
    subject { Guard::Dummy.new(engine: engine) }

    before do
      described_class.add_callback(listener, subject, :start_begin)
    end

    it "notifies the hooks" do
      module Guard
        class Dummy < Guard::Plugin
          def run_all
            hook :begin
            hook :end
          end
        end
      end

      expect(described_class).to receive(:notify).with(subject, :run_all_begin)
      expect(described_class).to receive(:notify).with(subject, :run_all_end)

      subject.run_all
    end

    it "passes the hooks name" do
      module Guard
        class Dummy < Guard::Plugin
          def start
            hook "my_hook"
          end
        end
      end

      expect(described_class).to receive(:notify).with(subject, :my_hook)

      subject.start
    end

    it "accepts extra arguments" do
      module Guard
        class Dummy < Guard::Plugin
          def stop
            hook :begin, "args"
            hook "special_sauce", "first_arg", "second_arg"
          end
        end
      end

      expect(described_class).to receive(:notify)
        .with(subject, :stop_begin, "args")

      expect(described_class).to receive(:notify)
        .with(subject, :special_sauce, "first_arg", "second_arg")

      subject.stop
    end
  end
end
