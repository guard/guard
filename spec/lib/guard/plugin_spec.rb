# frozen_string_literal: true

require "guard/plugin"

RSpec.describe Guard::Plugin do
  let!(:engine) { Guard.init }

  Guard::Foo = Class.new(Guard::Plugin)

  before do
    allow(ENV).to receive(:[]).with("GEM_REQUIREMENT_GUARD-FOO")
  end

  describe "#initialize" do
    it "assigns the defined watchers" do
      watchers = [double("foo")]

      expect(Guard::Foo.new(engine: engine, options: { watchers: watchers }).watchers).
        to eq watchers
    end

    it "assigns the defined options" do
      opts = { a: 1, b: 2 }

      expect(Guard::Foo.new(engine: engine, options: opts).options).to eq opts
    end

    it "display a deprecation message" do
      expect(Guard::UI).to receive(:deprecation).
        with(format(Guard::Deprecated::Plugin::INHERITHING_FROM_PLUGIN,
             "Foo", "/lib/guard/foo.rb", "Foo"))

      Guard::Foo.new(engine: engine)
    end

    context "with a group in the options" do
      it "assigns the given group" do
        expect(Guard::Foo.new(engine: engine, options: { group: :test }).group).
          to eq engine.groups.find(:test)
      end
    end

    context "without a group in the options" do
      it "assigns a default group" do
        expect(Guard::Foo.new(engine: engine).group).
          to eq engine.groups.find(:default)
      end
    end

    context "with a callback" do
      it "adds the callback" do
        block = instance_double(Proc)
        events = %i[start_begin start_end]
        callbacks = [{ events: events, listener: block }]
        plugin = Guard::Foo.new(engine: engine, options: { callbacks: callbacks })

        expect(plugin.callbacks).to eq(start_begin: [block], start_end: [block])
      end
    end
  end
end
