require 'spec_helper'

describe Guard::DeprecatedMethods do
  before(:all) do
    module TestModule
      extend Guard::DeprecatedMethods
    end
  end

  describe '.guards' do
    before { TestModule.stub(:plugins) }

    it 'displays a deprecation warning to the user' do
      expect(::Guard::UI).to receive(:deprecation).with(::Guard::Deprecator::GUARDS_DEPRECATION)

      TestModule.guards
    end

    it 'delegates to Guard.plugins' do
      expect(TestModule).to receive(:plugins).with(group: 'backend')

      TestModule.guards(group: 'backend')
    end
  end

  describe '.add_guard' do
    before { TestModule.stub(:add_plugin) }

    it 'displays a deprecation warning to the user' do
      expect(::Guard::UI).to receive(:deprecation).with(::Guard::Deprecator::ADD_GUARD_DEPRECATION)

      TestModule.add_guard('rspec')
    end

    it 'delegates to Guard.plugins' do
      expect(TestModule).to receive(:add_plugin).with('rspec', group: 'backend')

      TestModule.add_guard('rspec', group: 'backend')
    end
  end

  describe '.get_guard_class' do
    let(:plugin_util) { double('Guard::PluginUtil', plugin_class: true) }
    before { ::Guard::PluginUtil.stub(:new).and_return(plugin_util) }

    it 'displays a deprecation warning to the user' do
      expect(::Guard::UI).to receive(:deprecation).with(::Guard::Deprecator::GET_GUARD_CLASS_DEPRECATION)

      TestModule.get_guard_class('rspec')
    end

    it 'delegates to Guard::PluginUtil' do
      expect(::Guard::PluginUtil).to receive(:new).with('rspec') { plugin_util }
      expect(plugin_util).to receive(:plugin_class).with(fail_gracefully: false)

      TestModule.get_guard_class('rspec')
    end

    describe ':fail_gracefully' do
      it 'pass it to get_guard_class' do
        expect(::Guard::PluginUtil).to receive(:new).with('rspec') { plugin_util }
        expect(plugin_util).to receive(:plugin_class).with(fail_gracefully: true)

        TestModule.get_guard_class('rspec', true)
      end
    end
  end

  describe '.locate_guard' do
    let(:plugin_util) { double('Guard::PluginUtil', plugin_location: true) }
    before { ::Guard::PluginUtil.stub(:new).and_return(plugin_util) }

    it 'displays a deprecation warning to the user' do
      expect(::Guard::UI).to receive(:deprecation).with(::Guard::Deprecator::LOCATE_GUARD_DEPRECATION)

      TestModule.locate_guard('rspec')
    end

    it 'delegates to Guard::PluginUtil' do
      expect(::Guard::PluginUtil).to receive(:new).with('rspec') { plugin_util }
      expect(plugin_util).to receive(:plugin_location)

      TestModule.locate_guard('rspec')
    end
  end

  describe '.guard_gem_names' do
    before { ::Guard::PluginUtil.stub(:plugin_names) }

    it 'displays a deprecation warning to the user' do
      expect(::Guard::UI).to receive(:deprecation).with(::Guard::Deprecator::GUARD_GEM_NAMES_DEPRECATION)

      TestModule.guard_gem_names
    end

    it 'delegates to Guard::PluginUtil' do
      expect(Guard::PluginUtil).to receive(:plugin_names)

      TestModule.guard_gem_names
    end

  end

end
