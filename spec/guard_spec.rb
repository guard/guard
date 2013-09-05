require 'spec_helper'
require 'guard/plugin'

describe Guard do
  describe '.plugins' do
    before do
      stub_const 'Guard::FooBar', Class.new(Guard::Plugin)
      stub_const 'Guard::FooBaz', Class.new(Guard::Plugin)
      @guard_foo_bar_backend = described_class.add_plugin('foo_bar', :group => 'backend')
      @guard_foo_baz_backend = described_class.add_plugin('foo_baz', :group => 'backend')
      @guard_foo_bar_frontend = described_class.add_plugin('foo_bar', :group => 'frontend')
      @guard_foo_baz_frontend = described_class.add_plugin('foo_baz', :group => 'frontend')
    end

    it "return @plugins without any argument" do
      described_class.plugins.should eq subject.instance_variable_get("@plugins")
    end

    context "find a guard by as string/symbol" do
      it "find a guard by a string" do
        described_class.plugins('foo-bar').should eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "find a guard by a symbol" do
        described_class.plugins(:'foo-bar').should eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "returns nil if guard is not found" do
        described_class.plugins('foo-foo').should eq nil
      end
    end

    context "find plugins matching a regexp" do
      it "with matches" do
        described_class.plugins(/^foobar/).should eq [@guard_foo_bar_backend, @guard_foo_bar_frontend]
      end

      it "without matches" do
        described_class.plugins(/foo$/).should eq nil
      end
    end

    context "find plugins by their group" do
      it "group name is a string" do
        described_class.plugins(:group => 'backend').should eq [@guard_foo_bar_backend, @guard_foo_baz_backend]
      end

      it "group name is a symbol" do
        described_class.plugins(:group => :frontend).should eq [@guard_foo_bar_frontend, @guard_foo_baz_frontend]
      end

      it "returns nil if guard is not found" do
        described_class.plugins(:group => :unknown).should eq nil
      end
    end

    context "find plugins by their group & name" do
      it "group name is a string" do
        described_class.plugins(:group => 'backend', :name => 'foo-bar').should eq @guard_foo_bar_backend
      end

      it "group name is a symbol" do
        described_class.plugins(:group => :frontend, :name => :'foo-baz').should eq @guard_foo_baz_frontend
      end

      it "returns nil if guard is not found" do
        described_class.plugins(:group => :unknown, :name => :'foo-baz').should eq nil
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
        subject.groups.should eq subject.instance_variable_get("@groups")
      end
    end

    context 'with a string argument' do
      it 'returns a single group' do
        subject.groups('backend').should eq @group_backend
      end
    end

    context 'with a symbol argument matching a group' do
      it 'returns a single group' do
        subject.groups(:backend).should eq @group_backend
      end
    end

    context 'with a symbol argument not matching a group' do
      it 'returns nil' do
        subject.groups(:foo).should eq nil
      end
    end

    context 'with a regexp argument matching a group' do
      it 'returns an array of groups' do
        subject.groups(/^back/).should eq [@group_backend, @group_backflip]
      end
    end

    context 'with a regexp argument not matching a group' do
      it 'returns nil' do
        subject.groups(/back$/).should eq nil
      end
    end
  end

  describe '.add_plugin' do
    let(:plugin_util) { double('Guard::PluginUtil') }
    let(:guard_rspec) { double('Guard::RSpec instance') }

    before do
      ::Guard::PluginUtil.should_receive(:new).with('rspec') { plugin_util }
      plugin_util.stub(:initialize_plugin) { guard_rspec }

      ::Guard.reset_plugins
    end

    it 'delegates the plugin instantiation to Guard::PluginUtil' do
      plugin_util.should_receive(:initialize_plugin).with(:watchers => ['watcher'], :group => 'foo')

      ::Guard.add_plugin('rspec', :watchers => ['watcher'], :group => 'foo')
    end

    it "adds guard to the @plugins array" do
      ::Guard.add_plugin('rspec')

      ::Guard.plugins.should eq [guard_rspec]
    end
  end

  describe '.add_group' do
    before { ::Guard.reset_groups }

    it "accepts group name as string" do
      ::Guard.add_group('backend')
      ::Guard.groups[0].name.should eq :default
      ::Guard.groups[1].name.should eq :backend
    end

    it "accepts group name as symbol" do
      ::Guard.add_group(:backend)

      ::Guard.groups[0].name.should eq :default
      ::Guard.groups[1].name.should eq :backend
    end

    it "accepts options" do
      ::Guard.add_group(:backend, { :halt_on_fail => true })

      ::Guard.groups[0].options.should eq({})
      ::Guard.groups[1].options.should eq({ :halt_on_fail => true })
    end
  end

end
