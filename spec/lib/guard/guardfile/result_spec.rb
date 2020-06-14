# frozen_string_literal: true

require "guard/guardfile/result"

RSpec.describe Guard::Guardfile::Result, :stub_ui do
  let(:options) { {} }
  let(:valid_guardfile_string) { "group :foo; do guard :bar; end; end; " }
  let(:dsl) { instance_double("Guard::Dsl") }

  subject { described_class.new }

  describe "#plugin_names" do
    it "returns encountered names" do
      subject.plugins << ["foo", { bar: :baz }]
      subject.plugins << [:bar, { bar: :baz }]
      subject.plugins << ["baz", { bar: :baz }]

      expect(subject.plugin_names).to eq(%i[foo bar baz])
    end
  end

  describe "#notification" do
    it "stores notification as a hash" do
      hash = { foo: :bar }
      subject.notification.merge!(hash)

      expect(subject.notification).to eq(hash)
    end
  end

  describe "#interactor" do
    it "stores interactor as a hash" do
      hash = { foo: :bar }
      subject.interactor.merge!(hash)

      expect(subject.interactor).to eq(hash)
    end
  end

  describe "#groups" do
    it "defaults to { default: {} }" do
      expect(subject.groups).to eq(default: {})
    end

    it "stores groups as a hash" do
      hash = { foo: { opt1: :hello } }
      subject.groups.merge!(hash)

      expect(subject.groups).to eq(default: {}, **hash)
    end
  end

  describe "#plugins" do
    it "stores plugins as a hash" do
      hash = [:foo, { opt1: :hello }]
      subject.plugins << hash

      expect(subject.plugins).to eq([hash])
    end
  end

  describe "#ignore" do
    it "stores ignore as a hash" do
      regex = /foo/
      subject.ignore << regex

      expect(subject.ignore).to eq([regex])
    end
  end

  describe "#ignore_bang" do
    it "stores ignore_bang as a hash" do
      regex = /foo/
      subject.ignore_bang << regex

      expect(subject.ignore_bang).to eq([regex])
    end
  end

  describe "#logger" do
    it "stores logger as a hash" do
      hash = { foo: :bar }
      subject.logger.merge!(hash)

      expect(subject.logger).to eq(hash)
    end
  end

  describe "#scopes" do
    it "stores scopes as a hash" do
      hash = { foo: :bar }
      subject.scopes.merge!(hash)

      expect(subject.scopes).to eq(hash)
    end
  end

  describe "#directories" do
    it "stores directories as a hash" do
      string = "foo"
      subject.directories << string

      expect(subject.directories).to eq([string])
    end
  end

  describe "#clearing=" do
    it "stores clearing as a boolean" do
      subject.clearing = true

      expect(subject.clearing).to eq(true)
    end
  end
end
