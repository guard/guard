require 'spec_helper'

describe Guard::Options do

  describe '.initialize' do
    it 'behaves as an OpenStruct' do
      options = described_class.new(plugin: ['foo'], group: ['bar'])

      options.plugin.should eq ['foo']
      options.group.should eq ['bar']
    end

    it 'can be passed defaults' do
      options = described_class.new({}, ::Guard::Setuper::DEFAULT_OPTIONS)

      options.clear.should eq false
      options.notify.should eq true
      options.debug.should eq false
      options.group.should eq []
      options.plugin.should eq []
      options.watchdir.should eq nil
      options.guardfile.should eq nil
      options.no_interactions.should eq false
      options.no_bundler_warning.should eq false
      options.show_deprecations.should eq false
      options.latency.should eq nil
      options.force_polling.should eq false
    end

    it 'merges the sensible defaults to the given options' do
      options = described_class.new({ plugin: ['rspec'] }, ::Guard::Setuper::DEFAULT_OPTIONS)

      options.plugin.should eq ['rspec']
      options.group.should eq []
    end
  end

end
