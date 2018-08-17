require 'guard/options'

RSpec.describe Guard::Options do
  describe '.initialize' do
    it 'handles nil options' do
      expect { described_class.new(nil) }.to_not raise_error
    end

    it 'has indifferent access' do
      options = described_class.new({ foo: 'bar' }, 'foo2' => 'baz')

      expect(options[:foo]).to eq 'bar'
      expect(options['foo']).to eq 'bar'

      expect(options[:foo2]).to eq 'baz'
      expect(options['foo2']).to eq 'baz'
    end

    it 'can be passed defaults' do
      options = described_class.new({}, foo: 'bar')

      expect(options[:foo]).to eq 'bar'
    end

    it 'merges the sensible defaults to the given options' do
      options = described_class.new({ plugin: ['rspec'] }, plugin: ['test'])

      expect(options[:plugin]).to eq ['rspec']
    end
  end
end
