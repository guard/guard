# frozen_string_literal: true

require 'guard/internals/plugins'

RSpec.describe Guard::Internals::Plugins do
  def stub_plugin(name, group)
    instance_double('Guard::Plugin', name: name, group: group)
  end

  # TODO: all this is crazy
  let(:frontend) { instance_double('Guard::Group', name: :frontend) }
  let(:backend) { instance_double('Guard::Group', name: :backend) }

  let(:foo_bar_frontend) { stub_plugin('foobar', frontend) }
  let(:foo_baz_frontend) { stub_plugin('foobaz', frontend) }
  let(:foo_bar_backend) { stub_plugin('foobar', backend) }
  let(:foo_baz_backend) { stub_plugin('foobaz', backend) }

  let(:pu_foobar) { instance_double('Guard::PluginUtil') }
  let(:pu_foobaz) { instance_double('Guard::PluginUtil') }

  before do
    allow(Guard::PluginUtil).to receive(:new).with('foobar')
      .and_return(pu_foobar)

    allow(Guard::PluginUtil).to receive(:new).with('foobaz')
      .and_return(pu_foobaz)

    allow(pu_foobar).to receive(:initialize_plugin).with(group: 'frontend')
      .and_return(foo_bar_frontend)

    allow(pu_foobaz).to receive(:initialize_plugin).with(group: 'frontend')
      .and_return(foo_baz_frontend)

    allow(pu_foobar).to receive(:initialize_plugin).with(group: 'backend')
      .and_return(foo_bar_backend)

    allow(pu_foobaz).to receive(:initialize_plugin).with(group: 'backend')
      .and_return(foo_baz_backend)
  end

  describe '#all' do
    before do
      subject.add('foobar', group: 'frontend')
      subject.add('foobaz', group: 'frontend')
      subject.add('foobar', group: 'backend')
      subject.add('foobaz', group: 'backend')
    end

    context 'with no arguments' do
      let(:args) { [] }
      it 'returns all plugins' do
        expect(subject.all(*args)).to eq [
          foo_bar_frontend,
          foo_baz_frontend,
          foo_bar_backend,
          foo_baz_backend
        ]
      end
    end

    context 'find a plugin by as string' do
      it 'returns an array of plugins if plugins are found' do
        expect(subject.all('foo-bar'))
          .to match_array([foo_bar_backend, foo_bar_frontend])
      end
    end

    context 'find a plugin by as symbol' do
      it 'returns an array of plugins if plugins are found' do
        expect(subject.all(:'foo-bar'))
          .to match_array([foo_bar_backend, foo_bar_frontend])
      end

      it 'returns an empty array when no plugin is found' do
        expect(subject.all('foo-foo')).to be_empty
      end
    end

    context 'find plugins matching a regexp' do
      it 'returns an array of plugins if plugins are found' do
        expect(subject.all(/^foobar/))
          .to match_array([foo_bar_backend, foo_bar_frontend])
      end

      it 'returns an empty array when no plugin is found' do
        expect(subject.all(/foo$/)).to be_empty
      end
    end

    context 'find plugins by their group as a string' do
      it 'returns an array of plugins if plugins are found' do
        expect(subject.all(group: 'backend'))
          .to eq [foo_bar_backend, foo_baz_backend]
      end
    end

    context 'find plugins by their group as a symbol' do
      it 'returns an array of plugins if plugins are found' do
        expect(subject.all(group: :frontend))
          .to eq [foo_bar_frontend, foo_baz_frontend]
      end

      it 'returns an empty array when no plugin is found' do
        expect(subject.all(group: :unknown)).to be_empty
      end
    end

    context 'find plugins by their group & name' do
      it 'returns an array of plugins if plugins are found' do
        expect(subject.all(group: 'backend', name: 'foo-bar'))
          .to eq [foo_bar_backend]
      end

      it 'returns an empty array when no plugin is found' do
        expect(subject.all(group: :unknown, name: :'foo-baz'))
          .to be_empty
      end
    end
  end

  describe '#remove' do
    before do
      subject.add('foobar', group: 'frontend')
      subject.add('foobaz', group: 'frontend')
      subject.add('foobar', group: 'backend')
      subject.add('foobaz', group: 'backend')
    end

    it 'removes given plugin' do
      subject.remove(foo_bar_frontend)

      expect(subject.all).to match_array [
        foo_baz_frontend,
        foo_bar_backend,
        foo_baz_backend
      ]
    end
  end
end
