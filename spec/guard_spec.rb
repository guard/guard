require 'spec_helper'
require 'guard/plugin'

describe Guard do
  describe '.plugins' do
    before do
      stub_const 'Guard::FooBar', Class.new(Guard::Plugin)
      stub_const 'Guard::FooBaz', Class.new(Guard::Plugin)
      @guard_foo_bar_backend = described_class.add_plugin('foo_bar', group: 'backend')
      @guard_foo_baz_backend = described_class.add_plugin('foo_baz', group: 'backend')
      @guard_foo_bar_frontend = described_class.add_plugin('foo_bar', group: 'frontend')
      @guard_foo_baz_frontend = described_class.add_plugin('foo_baz', group: 'frontend')
    end

    it "return @plugins without any argument" do
      expect(described_class.plugins).to eq subject.instance_variable_get("@plugins")
    end

    context "find a plugin by as string" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins('foo-bar')).to eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end
    end

    context "find a plugin by as symbol" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(:'foo-bar')).to eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "returns an empty array when no plugin is found" do
        expect(described_class.plugins('foo-foo')).to be_empty
      end
    end

    context "find plugins matching a regexp" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(/^foobar/)).to eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "returns an empty array when no plugin is found" do
        expect(described_class.plugins(/foo$/)).to be_empty
      end
    end

    context "find plugins by their group as a string" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(group: 'backend')).to eq [@guard_foo_bar_backend, @guard_foo_baz_backend]
      end
    end

    context "find plugins by their group as a symbol" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(group: :frontend)).to eq [@guard_foo_bar_frontend, @guard_foo_baz_frontend]
      end

      it "returns an empty array when no plugin is found" do
        expect(described_class.plugins(group: :unknown)).to be_empty
      end
    end

    context "find plugins by their group & name" do
      it "returns an array of plugins if plugins are found" do
        expect(described_class.plugins(group: 'backend', name: 'foo-bar')).to eq [@guard_foo_bar_backend]
      end

      it "returns an empty array when no plugin is found" do
        expect(described_class.plugins(group: :unknown, name: :'foo-baz')).to be_empty
      end
    end
  end

  describe '.plugin' do
    before do
      stub_const 'Guard::FooBar', Class.new(Guard::Plugin)
      stub_const 'Guard::FooBaz', Class.new(Guard::Plugin)
      @guard_foo_bar_backend = described_class.add_plugin('foo_bar', group: 'backend')
      @guard_foo_baz_backend = described_class.add_plugin('foo_baz', group: 'backend')
      @guard_foo_bar_frontend = described_class.add_plugin('foo_bar', group: 'frontend')
      @guard_foo_baz_frontend = described_class.add_plugin('foo_baz', group: 'frontend')
    end

    context "find a plugin by a string" do
      it "returns the first plugin found" do
        expect(described_class.plugin('foo-bar')).to eq @guard_foo_bar_backend
      end
    end

    context "find a plugin by a symbol" do
      it "returns the first plugin found" do
        expect(described_class.plugin(:'foo-bar')).to eq @guard_foo_bar_backend
      end

      it "returns nil when no plugin is found" do
        expect(described_class.plugin('foo-foo')).to be_nil
      end
    end

    context "find plugins matching a regexp" do
      it "returns the first plugin found" do
        expect(described_class.plugin(/^foobar/)).to eq @guard_foo_bar_backend
      end

      it "returns nil when no plugin is found" do
        expect(described_class.plugin(/foo$/)).to be_nil
      end
    end

    context "find a plugin by its group as a string" do
      it "returns the first plugin found" do
        expect(described_class.plugin(group: 'backend')).to eq @guard_foo_bar_backend
      end
    end

    context "find plugins by their group as a symbol" do
      it "returns the first plugin found" do
        expect(described_class.plugin(group: :frontend)).to eq @guard_foo_bar_frontend
      end

      it "returns nil when no plugin is found" do
        expect(described_class.plugin(group: :unknown)).to be_nil
      end
    end

    context "find plugins by their group & name" do
      it "returns the first plugin found" do
        expect(described_class.plugin(group: 'backend', name: 'foo-bar')).to eq @guard_foo_bar_backend
      end

      it "returns nil when no plugin is found" do
        expect(described_class.plugin(group: :unknown, name: :'foo-baz')).to be_nil
      end
    end
  end

  describe '.groups' do
    subject do
      guard           = ::Guard.setup
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    context 'without no argument' do
      it 'returns all groups' do
        expect(subject.groups).to eq subject.instance_variable_get("@groups")
      end
    end

    context 'with a string argument' do
      it "returns an array of groups if plugins are found" do
        expect(subject.groups('backend')).to eq [@group_backend]
      end
    end

    context 'with a symbol argument matching a group' do
      it "returns an array of groups if plugins are found" do
        expect(subject.groups(:backend)).to eq [@group_backend]
      end
    end

    context 'with a symbol argument not matching a group' do
      it "returns an empty array when no group is found" do
        expect(subject.groups(:foo)).to be_empty
      end
    end

    context 'with a regexp argument matching a group' do
      it 'returns an array of groups' do
        expect(subject.groups(/^back/)).to eq [@group_backend, @group_backflip]
      end
    end

    context 'with a regexp argument not matching a group' do
      it "returns an empty array when no group is found" do
        expect(subject.groups(/back$/)).to be_empty
      end
    end
  end

  describe '.group' do
    subject do
      guard           = ::Guard.setup
      @group_backend  = guard.add_group(:backend)
      @group_backflip = guard.add_group(:backflip)
      guard
    end

    context 'with a string argument' do
      it "returns the first group found" do
        expect(subject.group('backend')).to eq @group_backend
      end
    end

    context 'with a symbol argument' do
      it "returns the first group found" do
        expect(subject.group(:backend)).to eq @group_backend
      end
    end

    context 'with a symbol argument not matching a group' do
      it "returns nil when no group is found" do
        expect(subject.group(:foo)).to be_nil
      end
    end

    context 'with a regexp argument matching a group' do
      it "returns the first group found" do
        expect(subject.group(/^back/)).to eq @group_backend
      end
    end

    context 'with a regexp argument not matching a group' do
      it "returns nil when no group is found" do
        expect(subject.group(/back$/)).to be_nil
      end
    end
  end

  describe '.add_plugin' do
    let(:plugin_util) { double('Guard::PluginUtil') }
    let(:guard_rspec) { double('Guard::RSpec instance') }

    before do
      expect(::Guard::PluginUtil).to receive(:new).with('rspec') { plugin_util }
      allow(plugin_util).to receive(:initialize_plugin) { guard_rspec }

      ::Guard.reset_plugins
    end

    it 'delegates the plugin instantiation to Guard::PluginUtil' do
      expect(plugin_util).to receive(:initialize_plugin).with(watchers: ['watcher'], group: 'foo')

      ::Guard.add_plugin('rspec', watchers: ['watcher'], group: 'foo')
    end

    it "adds guard to the @plugins array" do
      ::Guard.add_plugin('rspec')

      expect(::Guard.plugins).to eq [guard_rspec]
    end
  end

  describe '.add_group' do
    before { ::Guard.reset_groups }

    it "accepts group name as string" do
      ::Guard.add_group('backend')
      expect(::Guard.groups[0].name).to eq :default
      expect(::Guard.groups[1].name).to eq :backend
    end

    it "accepts group name as symbol" do
      ::Guard.add_group(:backend)

      expect(::Guard.groups[0].name).to eq :default
      expect(::Guard.groups[1].name).to eq :backend
    end

    it "accepts options" do
      ::Guard.add_group(:backend, { halt_on_fail: true })

      expect(::Guard.groups[0].options).to eq({})
      expect(::Guard.groups[1].options).to eq({ halt_on_fail: true })
    end
  end

end
