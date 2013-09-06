require 'spec_helper'
require 'guard/plugin'

describe Guard::Interactor do

  describe '.enabled & .enabled=' do
    before { described_class.enabled = nil }

    it 'returns true by default' do
      described_class.enabled.should be_true
    end

    context 'intreactor not enabled' do
      before { described_class.enabled = false }

      it 'returns false' do
        described_class.enabled.should be_false
      end
    end
  end

  describe '.options & .options=' do
    before { described_class.options = nil }

    it 'returns {} by default' do
      described_class.options.should eq({})
    end

    context 'options set to { :foo => :bar }' do
      before { described_class.options = { foo: :bar } }

      it 'returns { :foo => :bar }' do
        described_class.options.should eq({ foo: :bar })
      end
    end
  end

  describe '.convert_scope' do
    before do
      guard = ::Guard.setup

      stub_const 'Guard::Foo', Class.new(Guard::Plugin)
      stub_const 'Guard::Bar', Class.new(Guard::Plugin)

      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_plugin(:foo, { group: :backend })
      @bar_guard      = guard.add_plugin(:bar, { group: :frontend })
    end

    it 'returns a group scope' do
      scopes, _ = Guard::Interactor.convert_scope %w(backend)
      scopes.should eq({ groups: [@backend_group], plugins: [] })
      scopes, _ = Guard::Interactor.convert_scope %w(frontend)
      scopes.should eq({ groups: [@frontend_group], plugins: [] })
    end

    it 'returns a plugin scope' do
      scopes, _ = Guard::Interactor.convert_scope %w(foo)
      scopes.should eq({ plugins: [@foo_guard], groups: [] })
      scopes, _ = Guard::Interactor.convert_scope %w(bar)
      scopes.should eq({ plugins: [@bar_guard], groups: [] })
    end

    it 'returns multiple group scopes' do
      scopes, _ = Guard::Interactor.convert_scope %w(backend frontend)
      scopes.should eq({ groups: [@backend_group, @frontend_group], plugins: [] })
    end

    it 'returns multiple plugin scopes' do
      scopes, _ = Guard::Interactor.convert_scope %w(foo bar)
      scopes.should eq({ plugins: [@foo_guard, @bar_guard], groups: [] })
    end

    it 'returns a plugin and group scope' do
      scopes, _ = Guard::Interactor.convert_scope %w(foo backend)
      scopes.should eq({ plugins: [@foo_guard], groups: [@backend_group] })
    end

    it 'returns the unkown scopes' do
      _, unkown = Guard::Interactor.convert_scope %w(unkown scope)
      unkown.should eq %w(unkown scope)
    end
  end

end
