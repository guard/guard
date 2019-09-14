require "guard/api"

RSpec.describe Guard::API do
  let!(:engine) { Guard.init }
  let(:listener) { instance_double(Proc, call: nil) }

  let(:plugin_class) { Guard::Foo::Plugin }

  subject { plugin_class.new(engine: engine) }

  describe ".non_namespaced_classname" do
    it "remove the Guard:: namespace" do
      expect(plugin_class.non_namespaced_classname).to eq "Foo"
    end
  end

  describe ".non_namespaced_name" do
    it "remove the Guard:: namespace and downcase" do
      expect(plugin_class.non_namespaced_name).to eq "foo"
    end
  end

  describe ".template" do
    before do
      allow(File).to receive(:read)
    end

    it "reads the default template" do
      expect(File).to receive(:read).
        with("/guard-foo/lib/guard/foo/templates/Guardfile") { true }

      plugin_class.template("/guard-foo")
    end
  end

  describe "#initialize" do
    it "assigns the defined watchers" do
      watchers = [double("foo")]

      expect(plugin_class.new(engine: engine, options: { watchers: watchers }).watchers).to eq watchers
    end

    it "assigns the defined options" do
      options = { a: 1, b: 2 }

      expect(plugin_class.new(engine: engine, options: options).options).to eq options
    end

    context "with a group in the options" do
      it "assigns the given group" do
        expect(plugin_class.new(engine: engine, options: { group: :test }).group).to eq engine.groups.find(:test)
      end
    end

    context "without a group in the options" do
      it "assigns a default group" do
        expect(plugin_class.new(engine: engine).group).to eq engine.groups.find(:default)
      end
    end

    context "with a callback" do
      it "adds the callback" do
        block = instance_double(Proc)
        events = [:start_begin, :start_end]
        callbacks = [{ events: events, listener: block }]
        plugin = plugin_class.new(engine: engine, options: { callbacks: callbacks })

        expect(plugin.callbacks).to eq(start_begin: [block], start_end: [block])
      end
    end
  end

  describe "#name" do
    it "outputs the short plugin name" do
      expect(subject.name).to eq "foo"
    end
  end

  describe "#title" do
    it "outputs the plugin title" do
      expect(subject.title).to eq "Foo"
    end
  end

  describe "#to_s" do
    it "output the short plugin name" do
      expect(subject.to_s).
        to match(/#<Guard::Foo::Plugin @name=foo .*>/)
    end
  end

  describe "#add_callback" do
    it "can add a run_on_modifications callback" do
      subject.add_callback(:run_on_modifications_begin, listener)

      expect(subject.callbacks).to eq(run_on_modifications_begin: [listener])
    end

    it "can add multiple callbacks" do
      subject.add_callback([:event1, :event2], listener)

      expect(subject.callbacks).to eq(event1: [listener], event2: [listener])
    end
  end

  describe "#notify" do
    before do
      subject.add_callback(:start_begin, listener)
    end

    it "sends :call to the plugin's start_begin callback" do
      expect(listener).to receive(:call).with(subject, :start_begin, "args")

      subject.notify(:start_begin, "args")
    end

    it "runs only the given callbacks" do
      listener2 = double("listener2")
      subject.add_callback(:start_end, listener2)
      expect(listener2).to_not receive(:call)

      subject.notify(:start_begin)
    end
  end

  describe "#hook" do
    it "notifies the hooks" do
      expect(subject).to receive(:notify).with(:run_all_begin)
      expect(subject).to receive(:notify).with(:run_all_end)

      subject.run_all
    end

    it "passes the hooks name" do
      expect(subject).to receive(:notify).with(:my_hook)

      subject.start
    end

    it "accepts extra arguments" do
      expect(subject).to receive(:notify).with(:stop_begin, "args")
      expect(subject).to receive(:notify).with(:special_sauce, "first_arg", "second_arg")

      subject.stop
    end
  end
end
