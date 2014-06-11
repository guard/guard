require 'spec_helper'
require 'guard/plugin'

describe Guard::Interactor do

  describe '.enabled & .enabled=' do
    before do
      @interactor_enabled = described_class.enabled?
      described_class.enabled = nil
    end
    after { described_class.enabled = @interactor_enabled }

    it 'returns true by default' do
      expect(described_class).to be_enabled
    end

    context 'interactor not enabled' do
      before { described_class.enabled = false }

      it 'returns false' do
        expect(described_class).to_not be_enabled
      end
    end
  end

  describe '.options & .options=' do
    before { described_class.options = nil }

    it 'returns {} by default' do
      expect(described_class.options).to eq({})
    end

    context 'options set to { foo: :bar }' do
      before { described_class.options = { foo: :bar } }

      it 'returns { foo: :bar }' do
        expect(described_class.options).to eq(foo: :bar)
      end
    end
  end

  describe '.convert_scope' do
    before do
      allow(::Guard::Notifier).to receive(:turn_on) { nil }
      allow(Listen).to receive(:to).with(Dir.pwd, {})
      guard = ::Guard.setup

      stub_const 'Guard::Foo', Class.new(Guard::Plugin)
      stub_const 'Guard::Bar', Class.new(Guard::Plugin)

      @backend_group  = guard.add_group(:backend)
      @frontend_group = guard.add_group(:frontend)
      @foo_guard      = guard.add_plugin(:foo,  group: :backend)
      @bar_guard      = guard.add_plugin(:bar,  group: :frontend)
    end

    it 'returns a group scope' do
      scopes, _ = Guard::Interactor.convert_scope %w(backend)
      expect(scopes).to eq(groups: [@backend_group], plugins: [])
      scopes, _ = Guard::Interactor.convert_scope %w(frontend)
      expect(scopes).to eq(groups: [@frontend_group], plugins: [])
    end

    it 'returns a plugin scope' do
      scopes, _ = Guard::Interactor.convert_scope %w(foo)
      expect(scopes).to eq(plugins: [@foo_guard], groups: [])
      scopes, _ = Guard::Interactor.convert_scope %w(bar)
      expect(scopes).to eq(plugins: [@bar_guard], groups: [])
    end

    it 'returns multiple group scopes' do
      scopes, _ = Guard::Interactor.convert_scope %w(backend frontend)
      expected = { groups: [@backend_group, @frontend_group], plugins: [] }
      expect(scopes).to eq(expected)
    end

    it 'returns multiple plugin scopes' do
      scopes, _ = Guard::Interactor.convert_scope %w(foo bar)
      expect(scopes).to eq(plugins: [@foo_guard, @bar_guard], groups: [])
    end

    it 'returns a plugin and group scope' do
      scopes, _ = Guard::Interactor.convert_scope %w(foo backend)
      expect(scopes).to eq(plugins: [@foo_guard], groups: [@backend_group])
    end

    it 'returns the unkown scopes' do
      _, unkown = Guard::Interactor.convert_scope %w(unkown scope)
      expect(unkown).to eq %w(unkown scope)
    end
  end

  context 'interactor enabled' do
    let(:listener) { instance_double(Listen::Listener) }

    before do
      @interactor_enabled = described_class.enabled?
      described_class.enabled = nil
      ENV['GUARD_ENV'] = 'interactor_test'
      allow(Guard::Sheller).to receive(:run).with(*%w(hash stty)) { false }

      allow(::Guard::Notifier).to receive(:turn_on) { nil }
      allow(Listen).to receive(:to).with(Dir.pwd, {}) { listener }
      Guard.setup

      ::Guard.interactor.background
    end

    after do
      ::Guard.interactor.background
      ENV['GUARD_ENV'] = 'test'
      described_class.enabled = @interactor_enabled
    end

    describe '#foreground and #background' do
      let(:pry_output) { instance_double(IO) }

      before do
        allow(::Guard.interactor).to receive(:_block) {}

        allow(listener).to receive(:paused?).and_return(false)

      end

      it 'instantiate @thread as an instance of a Thread on #foreground' do
        ::Guard.interactor.foreground
        expect(::Guard.interactor.thread).to be_a(Thread)
      end

      it 'sets @thread to nil on #background' do
        ::Guard.interactor.background

        expect(::Guard.interactor.thread).to be_nil
      end
    end

    describe '#_prompt(ending_char)' do
      before do
        allow(::Guard).to receive(:scope).and_return({})
        allow(::Guard.scope).to receive(:[]).with(:plugins).and_return([])
        allow(::Guard.scope).to receive(:[]).with(:groups).and_return([])

        allow(listener).to receive(:paused?).and_return(false)

        expect(::Guard.interactor).to receive(:_clip_name).and_return('main')
      end
      let(:pry) { instance_double(Pry, input_array: []) }

      context 'Guard is not paused' do
        it 'displays "guard"' do
          expect(::Guard.interactor.send(:_prompt, '>').call(double, 0, pry)).
            to eq '[0] guard(main)> '
        end
      end

      context 'Guard is paused' do
        before do
          allow(listener).to receive(:paused?).and_return(true)
        end

        it 'displays "pause"' do
          expect(::Guard.interactor.send(:_prompt, '>').call(double, 0, pry)).
            to eq '[0] pause(main)> '
        end
      end

      context 'with a groups scope' do
        before do
          allow(::Guard.scope).to receive(:[]).with(:groups).
            and_return([double(title: 'Backend'), double(title: 'Frontend')])
        end

        it 'displays the group scope title in the prompt' do
          expect(::Guard.interactor.send(:_prompt, '>').call(double, 0, pry)).
            to eq '[0] Backend,Frontend guard(main)> '

        end
      end

      context 'with a plugins scope' do

        before do
          allow(::Guard.scope).to receive(:[]).with(:plugins).
                 and_return([double(title: 'RSpec'), double(title: 'Ronn')])
        end

        it 'displays the group scope title in the prompt' do
          result = ::Guard.interactor.send(:_prompt, '>').call(double, 0, pry)
          expect(result).to eq '[0] RSpec,Ronn guard(main)> '
        end
      end
    end
  end
end
