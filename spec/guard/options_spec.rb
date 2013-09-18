require 'spec_helper'

describe Guard::Options do

  describe '.initialize' do
    it 'behaves as an OpenStruct' do
      options = described_class.new(plugin: ['foo'], group: ['bar'])

      expect(options.plugin).to eq ['foo']
      expect(options.group).to eq ['bar']
    end

    it 'can be passed defaults' do
      options = described_class.new({}, ::Guard::Setuper::DEFAULT_OPTIONS)

      expect(options.clear).to eq false
      expect(options.notify).to eq true
      expect(options.debug).to eq false
      expect(options.group).to eq []
      expect(options.plugin).to eq []
      expect(options.watchdir).to eq nil
      expect(options.guardfile).to eq nil
      expect(options.no_interactions).to eq false
      expect(options.no_bundler_warning).to eq false
      expect(options.show_deprecations).to eq false
      expect(options.latency).to eq nil
      expect(options.force_polling).to eq false
    end

    it 'merges the sensible defaults to the given options' do
      options = described_class.new({ plugin: ['rspec'] }, ::Guard::Setuper::DEFAULT_OPTIONS)

      expect(options.plugin).to eq ['rspec']
      expect(options.group).to eq []
    end
  end

end
