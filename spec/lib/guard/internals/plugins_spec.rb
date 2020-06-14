# frozen_string_literal: true

require "guard/internals/plugins"

RSpec.describe Guard::Internals::Plugins, :stub_ui do
  include_context "with testing plugins"

  let(:evaluator) { instance_double("Guard::Guardfile::Evaluator", evaluate: true) }
  let(:frontend_group) { Guard::Group.new(:frontend) }
  let(:backend_group) { Guard::Group.new(:backend) }
  let!(:dummy_plugin) { subject.add("dummy", group: frontend_group) }
  let!(:doe_plugin) { subject.add("doe", group: frontend_group) }
  let!(:foobar_plugin) { subject.add("foobar", group: backend_group) }
  let!(:foobaz_plugin) { subject.add("foobaz", group: backend_group) }

  subject { described_class.new(evaluator) }

  describe "#add" do
    it "adds given plugin" do
      dummy_plugin2 = subject.add("dummy", group: "backend")

      expect(subject.all).to match_array [
        dummy_plugin,
        doe_plugin,
        foobar_plugin,
        foobaz_plugin,
        dummy_plugin2
      ]
    end
  end

  describe "#remove" do
    it "removes given plugin" do
      subject.remove(dummy_plugin)

      expect(subject.all).to match_array [
        doe_plugin,
        foobar_plugin,
        foobaz_plugin
      ]
    end
  end

  describe "#all" do
    context "with no arguments" do
      it "returns all plugins" do
        expect(subject.all).to match_array [
          dummy_plugin,
          doe_plugin,
          foobar_plugin,
          foobaz_plugin
        ]
      end
    end

    context "find a plugin by string" do
      it "returns an array of plugins if plugins are found" do
        expect(subject.all("dummy"))
          .to match_array([dummy_plugin])
      end
    end

    context "find a plugin by symbol" do
      it "returns an array of plugins if plugins are found" do
        expect(subject.all(:dummy))
          .to match_array([dummy_plugin])
      end

      it "returns an empty array when no plugin is found" do
        expect(subject.all("foo-foo")).to be_empty
      end
    end

    context "find plugins matching a regexp" do
      it "returns an array of plugins if plugins are found" do
        expect(subject.all(/^foo/))
          .to match_array([foobar_plugin, foobaz_plugin])
      end

      it "returns an empty array when no plugin is found" do
        expect(subject.all(/unknown$/)).to be_empty
      end
    end

    context "find plugins by their group as a string" do
      it "returns an array of plugins if plugins are found" do
        expect(subject.all(group: "frontend"))
          .to match_array([dummy_plugin, doe_plugin])
      end
    end

    context "find plugins by their group as a symbol" do
      it "returns an array of plugins if plugins are found" do
        expect(subject.all(group: :frontend))
          .to match_array([dummy_plugin, doe_plugin])
      end

      it "returns an empty array when no plugin is found" do
        expect(subject.all(group: :unknown)).to be_empty
      end
    end

    context "find plugins by their group & name" do
      it "returns an array of plugins if plugins are found" do
        expect(subject.all(group: "backend", name: "foobar"))
          .to match_array [foobar_plugin]
      end

      it "returns an empty array when no plugin is found" do
        expect(subject.all(group: :unknown, name: :'foo-baz'))
          .to be_empty
      end
    end
  end
end
