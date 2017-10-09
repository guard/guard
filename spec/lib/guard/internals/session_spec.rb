require "guard/internals/session"

RSpec.describe Guard::Internals::Session do
  let!(:engine) { Guard.init }
  let(:options) { {} }
  subject { described_class.new(engine: engine, options: options) }

  Guard::Foo = Class.new.include(Guard::API)
  Guard::Foobar = Class.new.include(Guard::API)

  before do
    subject.groups.add(:frontend)
    subject.groups.add(:backend)
    subject.plugins.add(:foo, group: :frontend)
    subject.plugins.add(:foo, group: :backend)
    subject.plugins.add(:foobar, group: :frontend)
    subject.plugins.add(:foobar, group: :backend)
  end

  describe "#initialize" do
    describe "#listener_args" do
      context "with a single watchdir" do
        let(:options) { { watchdir: ["/usr"] } }
        let(:dir) { Gem.win_platform? ? "C:/usr" : "/usr" }

        it { expect(subject.listener_args).to eq [:to, dir, {}] }
      end

      context "with multiple watchdirs" do
        let(:options) { { watchdir: ["/usr", "/bin"] } }
        let(:dir1) { Gem.win_platform? ? "C:/usr" : "/usr" }
        let(:dir2) { Gem.win_platform? ? "C:/bin" : "/bin" }

        it { expect(subject.listener_args).to eq [:to, dir1, dir2, {}] }
      end

      context "with force_polling option" do
        let(:options) { { force_polling: true } }

        it { expect(subject.listener_args).to eq [:to, Dir.pwd, force_polling: true] }
      end

      context "with latency option" do
        let(:options) { { latency: 1.5 } }

        it { expect(subject.listener_args).to eq [:to, Dir.pwd, latency: 1.5] }
      end
    end

    context "with the plugin option" do
      let(:options) do
        {
          plugin: %w(foo foobar),
          guardfile_contents: "guard :foo do; end; "\
          "guard :foobar do; end; guard :foobaz do; end"
        }
      end

      it "initializes the plugin scope" do
        allow(subject.plugins).to receive(:add).with("foo", {})
        allow(subject.plugins).to receive(:add).with("foobar", {})

        expect(subject.cmdline_plugins).to match_array(%w(foo foobar))
      end
    end

    context "with the group option" do
      let(:options) do
        {
          group: %w(backend frontend),
          guardfile_contents: "group :backend do; end; "\
          "group :frontend do; end; group :excluded do; end"
        }
      end

      it "initializes the group scope" do
        expect(subject.cmdline_groups).to match_array(%w(backend frontend))
      end
    end
  end

  describe "#clearing" do
    context "when not set" do
      context "when clearing is not set from commandline" do
        it { is_expected.to_not be_clearing }
      end

      context "when clearing is set from commandline" do
        let(:options) { { clear: false } }
        it { is_expected.to_not be_clearing }
      end
    end

    context "when set from guardfile" do
      context "when set to :on" do
        before { subject.clearing(true) }
        it { is_expected.to be_clearing }
      end

      context "when set to :off" do
        before { subject.clearing(false) }
        it { is_expected.to_not be_clearing }
      end
    end
  end

  describe "#guardfile_ignore=" do
    context "when set from guardfile" do
      before { subject.guardfile_ignore = [/foo/] }
      specify { expect(subject.guardfile_ignore).to eq([/foo/]) }
    end

    context "when set multiple times from guardfile" do
      before do
        subject.guardfile_ignore = [/foo/]
        subject.guardfile_ignore = [/bar/]
      end
      specify { expect(subject.guardfile_ignore).to eq([/foo/, /bar/]) }
    end

    context "when unset" do
      specify { expect(subject.guardfile_ignore).to eq([]) }
    end
  end

  describe "#guardfile_ignore_bang=" do
    context "when set from guardfile" do
      before { subject.guardfile_ignore_bang = [/foo/] }
      specify { expect(subject.guardfile_ignore_bang).to eq([/foo/]) }
    end

    context "when unset" do
      specify { expect(subject.guardfile_ignore_bang).to eq([]) }
    end
  end

  describe "#guardfile_scope" do
    before do
      subject.guardfile_scope(scope)
    end

    context "with a groups scope" do
      let(:scope) { { groups: [:foo] } }
      it "sets the groups" do
        expect(subject.guardfile_group_scope).to eq([:foo])
      end
    end

    context "with a group scope" do
      let(:scope) { { group: [:foo] } }
      it "sets the groups" do
        expect(subject.guardfile_group_scope).to eq([:foo])
      end
    end

    context "with a plugin scope" do
      let(:scope) { { plugin: [:foo] } }
      it "sets the plugins" do
        expect(subject.guardfile_plugin_scope).to eq([:foo])
      end
    end

    context "with a plugins scope" do
      let(:scope) { { plugins: [:foo] } }
      it "sets the plugins" do
        expect(subject.guardfile_plugin_scope).to eq([:foo])
      end
    end
  end

  describe ".convert_scope" do
    it "returns a group scope" do
      scopes, = subject.convert_scope %w(backend)

      expect(scopes).to eq(groups: [subject.groups.find(:backend)], plugins: [])
    end

    it "returns a plugin scope" do
      scopes, = subject.convert_scope %w(foo)

      expect(scopes).to eq(plugins: [subject.plugins.find(:foo)], groups: [])
    end

    it "returns multiple group scopes" do
      scopes, = subject.convert_scope %w(backend frontend)
      expected = { groups: [subject.groups.find(:backend), subject.groups.find(:frontend)], plugins: [] }

      expect(scopes).to eq(expected)
    end

    it "returns multiple plugin scopes" do
      scopes, = subject.convert_scope %w(foo foobar)

      expect(scopes).to eq(plugins: [subject.plugins.find(:foo), subject.plugins.find(:foobar)], groups: [])
    end

    it "returns a plugin and group scope" do
      scopes, = subject.convert_scope %w(foo backend)

      expect(scopes).to eq(plugins: [subject.plugins.find(:foo)], groups: [subject.groups.find(:backend)])
    end

    it "returns the unkown scopes" do
      _, unknown = subject.convert_scope %w(unknown scope)

      expect(unknown).to eq %w(unknown scope)
    end
  end

  describe "#guardfile_notification=" do
    context "when set from guardfile" do
      before do
        subject.guardfile_notification = { foo: { bar: :baz } }
      end

      specify do
        expect(subject.notify_options).to eq(
          notify: true,
          notifiers: {
            foo: { bar: :baz }
          }
        )
      end
    end

    context "when set multiple times from guardfile" do
      before do
        subject.guardfile_notification = { foo: { param: 1 } }
        subject.guardfile_notification = { bar: { param: 2 } }
      end

      it "merges results" do
        expect(subject.notify_options).to eq(
          notify: true,
          notifiers: {
            foo: { param: 1 },
            bar: { param: 2 }
          }
        )
      end
    end

    context "when unset" do
      specify do
        expect(subject.notify_options).to eq(notify: true, notifiers: {})
      end
    end
  end
end
