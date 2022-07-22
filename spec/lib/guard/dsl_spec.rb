# frozen_string_literal: true

require "guard/dsl"

RSpec.describe Guard::Dsl do
  describe "#notification" do
    it "stores notification as a hash when :off is passed" do
      subject.notification(:off)

      expect(subject.result.notification).to eq(off: {})
    end

    it "stores notification as a hash" do
      options = { foo: :bar }
      subject.notification(:notifier, options)

      expect(subject.result.notification).to eq(notifier: options)
    end
  end

  describe "#interactor" do
    it "stores interactor as a hash" do
      hash = { foo: :bar }
      subject.interactor(hash)

      expect(subject.result.interactor).to eq(hash)
    end
  end

  describe "#group" do
    it "stores groups as a hash" do
      options = { foo: :bar }
      subject.group(:frontend, options) { subject.guard(:foo) }
      subject.group(:backend, options) { subject.guard(:foo) }

      expect(subject.result.groups).to eq({ default: {}, frontend: options, backend: options })
    end
  end

  describe "#guard" do
    it "stores plugins as a hash" do
      options1 = { opt1: :bar }
      options2 = { opt2: :baz }
      subject.group(:frontend) { subject.guard(:foo, options1) }
      subject.guard(:foo, options2)
      plugin_options1 = options1.merge(callbacks: [], watchers: [], group: :frontend)
      plugin_options2 = options2.merge(callbacks: [], watchers: [], group: :default)

      expect(subject.result.plugins).to eq([[:foo, plugin_options1], [:foo, plugin_options2]])
    end
  end

  describe "#ignore" do
    it "stores ignore as a hash" do
      regex = /foo/
      subject.ignore(regex)

      expect(subject.result.ignore).to eq([regex])
    end
  end

  describe "#ignore_bang" do
    it "stores ignore_bang as a hash" do
      regex = /foo/
      subject.ignore!(regex)

      expect(subject.result.ignore_bang).to eq([regex])
    end
  end

  describe "#logger" do
    it "stores logger as a hash" do
      hash = { foo: :bar }
      subject.logger(hash)

      expect(subject.result.logger).to eq(hash)
    end
  end

  describe "#scopes" do
    it "stores scopes as a hash" do
      hash = { foo: :bar }
      subject.scope(hash)

      expect(subject.result.scopes).to eq(hash)
    end
  end

  describe "#directories" do
    it "stores directories as a hash when given as a string" do
      string = "lib"
      subject.directories(string)

      expect(subject.result.directories).to eq([string])
    end

    it "stores directories as a hash when given as an array" do
      array = %w[bin lib]
      subject.directories(array)

      expect(subject.result.directories).to eq(array)
    end
  end

  describe "#clearing=" do
    it "stores clearing as a true when :on" do
      subject.clearing(:on)

      expect(subject.result.clearing).to eq(true)
    end

    it "stores clearing as a false otherwise" do
      subject.clearing(:off)

      expect(subject.result.clearing).to eq(false)
    end
  end
end
