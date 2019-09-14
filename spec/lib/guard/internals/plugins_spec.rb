# frozen_string_literal: true

require "guard/internals/plugins"

RSpec.describe Guard::Internals::Plugins do
  let!(:engine) { Guard.init }

  subject { described_class.new(engine: engine) }

  describe "#all" do
    before do
      subject.add("foo", group: "frontend")
      subject.add("foobar", group: "frontend")
      subject.add("foo", group: "backend")
      subject.add("foobar", group: "backend")
    end

    context "with no arguments" do
      it "returns all plugins" do
        expect(all_name_and_groups(nil)).
          to eq [
            ["foobar", :frontend],
            ["foobaz", :frontend],
            ["foobar", :backend],
            ["foobaz", :backend]
          ]
      end
    end

    context "find a plugin by as string" do
      it "returns an array of plugins if plugins are found" do
          expect(all_name_and_groups("foo-bar"))
            .to eq [
              ["foo", :frontend],
              ["foo", :backend]
            ]
      end
    end

    context "find a plugin by as symbol" do
      it "returns an array of plugins if plugins are found" do
        expect(all_name_and_groups(:"foo-bar"))
          .to eq [
            ["foo", :frontend],
            ["foo", :backend]
          ]
      end

      it "returns an empty array when no plugin is found" do
        expect(all_name_and_groups("foo-foo")).to be_empty
      end
    end

    context "find plugins matching a regexp" do
      it "returns an array of plugins if plugins are found" do
        expect(all_name_and_groups(/^foo/))
          .to eq [
            ["foo", :frontend],
            ["foo", :backend]
          ]
      end

      it "returns an empty array when no plugin is found" do
        expect(subject.all(/foo$/)).to be_empty
      end
    end

    context "find plugins by their group as a string" do
      it "returns an array of plugins if plugins are found" do
        expect(all_name_and_groups(group: "backend"))
          .to eq [
            ["foo", :backend],
            ["foobar", :backend]
          ]
      end
    end

    context "find plugins by their group as a symbol" do
      it "returns an array of plugins if plugins are found" do
        expect(all_name_and_groups(group: :frontend))
          .to eq [
            ["foo", :frontend],
            ["foobar", :frontend]
          ]
      end

      it "returns an empty array when no plugin is found" do
        expect(subject.all(group: :unknown)).to be_empty
      end
    end

    context "find plugins by their group & name" do
      it "returns an array of plugins if plugins are found" do
        expect(all_name_and_groups(group: "backend", name: "foo-bar"))
          .to eq [
            ["foo", :backend]
          ]
      end

      it "returns an empty array when no plugin is found" do
        expect(all_name_and_groups(group: :unknown, name: :'foo-baz'))
          .to be_empty
      end
    end
  end

  describe "#remove" do
    before do
      subject.add("foo", group: "frontend")
      subject.add("foobar", group: "frontend")
      subject.add("foo", group: "backend")
      subject.add("foobar", group: "backend")
    end

    it "removes given plugin" do
      subject.remove(subject.all(group: "frontend", name: "foo-bar")[0])

      expect(all_name_and_groups(nil)).
        to match_array [
          ["foobar", :frontend],
          ["foo", :backend],
          ["foobar", :backend]
        ]
    end
  end

  def all_name_and_groups(filter)
    subject.all(filter).map { |plugin| [plugin.name, plugin.group.name] }
  end
end
