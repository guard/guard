# frozen_string_literal: true

require "guard/internals/session"

RSpec.describe Guard::Internals::Session, :stub_ui do
  include_context "with engine"

  let(:options) { {} }
  subject { engine.session }

  describe "#initialize" do
    describe "#listener_args" do
      subject { described_class.new(engine, options).listener_args }

      context "with a single watchdir" do
        let(:options) { { watchdirs: ["/usr"] } }
        let(:dir) { Gem.win_platform? ? "C:/usr" : "/usr" }

        it { is_expected.to eq [:to, dir, {}] }
      end

      context "with multiple watchdirs" do
        let(:options) { { watchdirs: ["/usr", "/bin"] } }
        let(:dir1) { Gem.win_platform? ? "C:/usr" : "/usr" }
        let(:dir2) { Gem.win_platform? ? "C:/bin" : "/bin" }
        it { is_expected.to eq [:to, dir1, dir2, {}] }
      end

      context "with force_polling option" do
        let(:options) { { force_polling: true } }
        it { is_expected.to eq [:to, Dir.pwd, force_polling: true] }
      end

      context "with latency option" do
        let(:options) { { latency: 1.5 } }
        it { is_expected.to eq [:to, Dir.pwd, latency: 1.5] }
      end
    end

    context "with the plugin option" do
      let(:options) do
        {
          plugin: %w[dummy doe]
        }
      end

      it "initializes the plugin scope" do
        expect(subject.cmdline_scopes.plugins).to match_array(%w[dummy doe])
      end
    end

    context "with the group option" do
      let(:options) do
        {
          group: %w[backend frontend]
        }
      end

      it "initializes the group scope" do
        expect(subject.cmdline_scopes.groups).to match_array(%w[backend frontend])
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
      subject.guardfile_scopes = scopes
    end

    context "with a groups scope" do
      let(:scopes) { { groups: [:foo] } }

      it "sets the groups" do
        expect(subject.guardfile_scopes.groups).to eq([:foo])
      end
    end

    context "with a group scope" do
      let(:scopes) { { group: [:foo] } }

      it "sets the groups" do
        expect(subject.guardfile_scopes.groups).to eq([:foo])
      end
    end

    context "with a plugin scope" do
      let(:scopes) { { plugin: [:foo] } }

      it "sets the plugins" do
        expect(subject.guardfile_scopes.plugins).to eq([:foo])
      end
    end

    context "with a plugins scope" do
      let(:scopes) { { plugins: [:foo] } }

      it "sets the plugins" do
        expect(subject.guardfile_scopes.plugins).to eq([:foo])
      end
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

  describe "#convert_scopes" do
    let!(:frontend_group) { groups.add("frontend") }
    let!(:backend_group) { groups.add("backend") }
    let!(:dummy_plugin) { plugins.add("dummy", group: "frontend") }
    let!(:doe_plugin) { plugins.add("doe", group: "backend") }

    it "returns a group scope" do
      scopes, = subject.convert_scopes(:backend)

      expect(scopes).to eq(groups: [:backend], plugins: [])

      scopes, = subject.convert_scopes(%w[frontend])

      expect(scopes).to eq(groups: [:frontend], plugins: [])
    end

    it "returns a plugin scope" do
      scopes, = subject.convert_scopes("dummy")

      expect(scopes).to eq(plugins: [:dummy], groups: [])

      scopes, = subject.convert_scopes(%w[doe])

      expect(scopes).to eq(plugins: [:doe], groups: [])
    end

    it "returns multiple group scopes" do
      scopes, = subject.convert_scopes(%w[backend frontend])
      expected = { groups: %i[backend frontend], plugins: [] }

      expect(scopes).to eq(expected)
    end

    it "returns multiple plugin scopes" do
      scopes, = subject.convert_scopes(%w[dummy doe])
      expect(scopes).to eq(plugins: %i[dummy doe], groups: [])
    end

    it "returns a plugin and group scope" do
      scopes, = subject.convert_scopes(%w[backend dummy])
      expect(scopes).to eq(groups: [:backend], plugins: [:dummy])
    end

    it "returns the unkown scopes" do
      _, unknown = subject.convert_scopes(%w[unknown scope])

      expect(unknown).to eq(%w[unknown scope])
    end
  end

  describe "#grouped_plugins" do
    let!(:frontend_group) { subject.groups.add("frontend") }
    let!(:backend_group) { subject.groups.add("backend") }
    let!(:dummy_plugin) { subject.plugins.add("dummy", group: frontend_group) }
    let!(:doe_plugin) { subject.plugins.add("doe", group: backend_group) }

    context "with no arguments given" do
      it "returns all the grouped plugins" do
        expect(subject.grouped_plugins).to eq({ frontend_group => [dummy_plugin], backend_group => [doe_plugin] })
      end
    end

    context "with a single :plugins scope given" do
      it "returns the given grouped plugins" do
        expect(subject.grouped_plugins(plugins: :dummy)).to eq({ frontend_group => [dummy_plugin] })
      end
    end

    context "with multiple :plugins scope given" do
      it "returns the given grouped plugins" do
        expect(subject.grouped_plugins(plugins: %i[dummy doe]))
          .to eq({ frontend_group => [dummy_plugin], backend_group => [doe_plugin] })
      end
    end

    context "with a single :groups scope given" do
      it "returns the given grouped plugins" do
        expect(subject.grouped_plugins(groups: :frontend)).to eq({ frontend_group => [dummy_plugin] })
      end
    end

    context "with multiple :plugins scope given" do
      it "returns the given grouped plugins" do
        expect(subject.grouped_plugins(groups: %i[frontend backend]))
          .to eq({ frontend_group => [dummy_plugin], backend_group => [doe_plugin] })
      end
    end

    shared_examples "scopes titles" do
      it "return the titles for the given scopes" do
        expect(subject.grouped_plugins).to eq({ frontend_group => [dummy_plugin] })
      end
    end

    shared_examples "empty scopes titles" do
      it "return an empty array" do
        expect(subject.grouped_plugins).to be_empty
      end
    end

    { groups: "frontend", plugins: "dummy" }.each do |scope, name|
      let(:given_scope) { scope }
      let(:name_for_scope) { name }

      describe "#{scope.inspect} (#{name})" do
        context "when set from interactor" do
          before do
            session.interactor_scopes = { given_scope => name_for_scope }
          end

          it_behaves_like "scopes titles"
        end

        context "when not set in interactor" do
          context "when set in commandline" do
            let(:options) { { given_scope => [name_for_scope] } }

            it_behaves_like "scopes titles"
          end

          context "when not set in commandline" do
            context "when set in Guardfile" do
              before do
                session.guardfile_scopes = { given_scope => name_for_scope }
              end

              it_behaves_like "scopes titles"
            end
          end
        end
      end
    end

    describe "with groups and plugins scopes" do
      before do
        session.interactor_scopes = { groups: "frontend", plugins: "dummy" }
      end

      it "return only the plugins titles" do
        expect(subject.grouped_plugins).to eq({ frontend_group => [dummy_plugin] })
      end
    end
  end

  describe "#scope_titles" do
    let!(:frontend_group) { subject.groups.add("frontend") }
    let!(:dummy_plugin) { subject.plugins.add("dummy", group: "frontend") }

    context "with no arguments given" do
      it "returns 'all'" do
        expect(subject.scope_titles).to eq ["all"]
      end
    end

    context "with a 'plugins' scope given" do
      it "returns the plugins' titles" do
        expect(subject.scope_titles([:dummy])).to eq ["Dummy"]
      end
    end

    context "with a 'groups' scope given" do
      it "returns the groups' titles" do
        expect(subject.scope_titles(:default)).to eq ["Default"]
      end
    end

    context "with a 'groups' scope given" do
      it "returns the groups' titles" do
        expect(subject.scope_titles([:frontend])).to eq ["Frontend"]
      end
    end

    context "with both 'plugins' and 'groups' scopes given" do
      it "returns only the plugins' titles" do
        expect(subject.scope_titles(%i[dummy frontend])).to eq ["Dummy"]
      end
    end

    shared_examples "scopes titles" do
      it "return the titles for the given scopes" do
        expect(subject.scope_titles).to eq subject.public_send(given_scope).all(name_for_scope).map(&:title)
      end
    end

    shared_examples "empty scopes titles" do
      it "return an empty array" do
        expect(subject.scope_titles).to be_empty
      end
    end

    { groups: "frontend", plugins: "dummy" }.each do |scope, name|
      let(:given_scope) { scope }
      let(:name_for_scope) { name }

      describe "#{scope.inspect} (#{name})" do
        context "when set from interactor" do
          before do
            session.interactor_scopes = { given_scope => name_for_scope }
          end

          it_behaves_like "scopes titles"
        end

        context "when not set in interactor" do
          context "when set in commandline" do
            let(:options) { { given_scope => [name_for_scope] } }

            it_behaves_like "scopes titles"
          end

          context "when not set in commandline" do
            context "when set in Guardfile" do
              before do
                session.guardfile_scopes = { given_scope => name_for_scope }
              end

              it_behaves_like "scopes titles"
            end
          end
        end
      end
    end

    describe "with groups and plugins scopes" do
      before do
        session.interactor_scopes = { groups: "frontend", plugins: "dummy" }
      end

      it "return only the plugins titles" do
        expect(subject.scope_titles).to eq subject.plugins.all.map(&:title)
      end
    end
  end
end
