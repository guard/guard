# frozen_string_literal: true

require 'guard'

RSpec.describe Guard do
  # Initialize before Guard::Interactor const is stubbed
  let!(:interactor) { instance_double('Guard::Interactor') }

  let(:guardfile) { File.expand_path('Guardfile') }
  let(:traps) { Guard::Internals::Traps }

  let(:evaluator) { instance_double('Guard::Guardfile::Evaluator') }

  let(:plugins) { instance_double('Guard::Internals::Plugins') }
  let(:scope) { instance_double('Guard::Internals::Scope') }
  let(:session) { instance_double('Guard::Internals::Session') }
  let(:state) { instance_double('Guard::Internals::State') }
  let(:queue) { instance_double('Guard::Internals::Queue') }

  before do
    allow(Guard::Interactor).to receive(:new).and_return(interactor)
    allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)

    allow(session).to receive(:debug?).and_return(false)
    allow(session).to receive(:plugins).and_return(plugins)
    allow(state).to receive(:session).and_return(session)
    allow(Guard::Internals::Session).to receive(:new).and_return(session)
    allow(Guard::Internals::Scope).to receive(:new).and_return(scope)
    allow(Guard::Internals::Queue).to receive(:new).and_return(queue)
  end

  # TODO: setup has too many responsibilities
  describe '.setup' do
    subject { Guard.setup(options) }

    let(:options) { { my_opts: true, guardfile: guardfile } }

    let(:listener) { instance_double('Listen::Listener') }

    before do
      allow(Listen).to receive(:to).with(Dir.pwd, {}) { listener }

      stub_guardfile(' ')
      stub_user_guard_rb

      g1 = instance_double('Guard::Group', name: :common, options: {})
      g2 = instance_double('Guard::Group', name: :default, options: {})
      allow(Guard::Group).to receive(:new).with(:common).and_return(g1)
      allow(Guard::Group).to receive(:new).with(:default).and_return(g2)

      allow(evaluator).to receive(:inline?).and_return(false)
      allow(evaluator).to receive(:custom?).and_return(false)
      allow(evaluator).to receive(:evaluate)
      allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)

      allow(Guard::Notifier).to receive(:connect)

      allow(Guard::UI).to receive(:reset_and_clear)
      allow(plugins).to receive(:all).and_return([])

      allow(session).to receive(:listener_args).and_return([:to, Dir.pwd, {}])
      allow(session).to receive(:evaluator_options).and_return({})
      allow(session).to receive(:cmdline_groups).and_return({})
      allow(session).to receive(:cmdline_plugins).and_return({})
      allow(session).to receive(:notify_options).and_return(notify: true)
      allow(session).to receive(:interactor_name).and_return(:foo)
      allow(session).to receive(:guardfile_ignore).and_return([])
      allow(session).to receive(:guardfile_ignore_bang).and_return([])

      allow(listener).to receive(:ignore)
      allow(listener).to receive(:ignore!)

      allow(Guard::Internals::State).to receive(:new).and_return(state)
    end

    it 'returns itself for chaining' do
      expect(subject).to be Guard
    end

    it 'initializes the listener' do
      allow(Listen).to receive(:to)
        .with('/foo', latency: 2, wait_for_delay: 1).and_return(listener)

      allow(session).to receive(:listener_args).and_return(
        [:to, '/foo', { latency: 2, wait_for_delay: 1 }]
      )
      subject
    end

    it 'initializes the interactor' do
      expect(Guard::Interactor).to receive(:new).with(false)
      subject
    end

    context 'trapping signals' do
      before do
        allow(traps).to receive(:handle)
      end

      it 'sets up USR1 trap for pausing' do
        expect(traps).to receive(:handle).with('USR1') { |_, &b| b.call }
        expect(Guard).to receive(:async_queue_add)
          .with([:guard_pause, :paused])
        subject
      end

      it 'sets up USR2 trap for unpausing' do
        expect(traps).to receive(:handle).with('USR2') { |_, &b| b.call }
        expect(Guard).to receive(:async_queue_add)
          .with([:guard_pause, :unpaused])
        subject
      end

      it 'sets up INT trap for cancelling or quitting interactor' do
        expect(traps).to receive(:handle).with('INT') { |_, &b| b.call }
        expect(interactor).to receive(:handle_interrupt)
        subject
      end
    end

    it 'evaluates the Guardfile' do
      expect(evaluator).to receive(:evaluate)
      allow(Guard::Guardfile::Evaluator).to receive(:new).and_return(evaluator)

      subject
    end

    describe 'listener' do
      subject { listener }

      context "with ignores 'ignore(/foo/)' and 'ignore!(/bar/)'" do
        before do
          allow(evaluator).to receive(:evaluate) do
            allow(session).to receive(:guardfile_ignore).and_return([/foo/])
            allow(session).to receive(:guardfile_ignore_bang)
              .and_return([/bar/])
          end
          Guard.setup(options)
        end

        it { is_expected.to have_received(:ignore).with([/foo/]) }
        it { is_expected.to have_received(:ignore!).with([/bar/]) }
      end

      context 'without ignores' do
        before { Guard.setup(options) }
        it { is_expected.to_not have_received(:ignore) }
        it { is_expected.to_not have_received(:ignore!) }
      end
    end

    it 'displays an error message when no guard are defined in Guardfile' do
      expect(Guard::UI).to receive(:error)
        .with('No plugins found in Guardfile, please add at least one.')

      subject
    end

    it 'connects to the notifier' do
      expect(Guard::Notifier).to receive(:connect).with(notify: true)
      subject
    end

    context 'with the group option' do
      let(:options) { { group: %w[frontend backend] } }
      it 'passes options to session' do
        expect(Guard::Internals::State).to receive(:new).with(options)
        subject
      end
    end

    context 'with the plugin option' do
      let(:options) { { plugin: %w[cucumber jasmine] } }
      it 'passes options to session' do
        expect(Guard::Internals::State).to receive(:new).with(options)
        subject
      end
    end

    describe '.interactor' do
      subject { Guard::Interactor }

      before do
        expect(session).to receive(:interactor_name).and_return(type)
        Guard.setup(options)
      end

      context 'with interactions enabled' do
        let(:type) { :pry_wrapper }
        let(:options) { { no_interactions: false } }
        it { is_expected.to have_received(:new).with(false) }
      end

      context 'with interactions disabled' do
        let(:type) { :sleep }
        let(:options) { { no_interactions: true } }
        it { is_expected.to have_received(:new).with(true) }
      end
    end

    describe 'UI' do
      subject { Guard::UI }

      context 'when clearing is configured' do
        before { Guard.setup(options) }
        it { is_expected.to have_received(:reset_and_clear) }
      end
    end
  end

  describe '._relative_pathname' do
    subject { Guard.send(:_relative_pathname, raw_path) }

    let(:pwd) { Pathname('/project') }

    before { allow(Pathname).to receive(:pwd).and_return(pwd) }

    context 'with file in project directory' do
      let(:raw_path) { '/project/foo' }
      it { is_expected.to eq(Pathname('foo')) }
    end

    context 'with file within project' do
      let(:raw_path) { '/project/spec/models/foo_spec.rb' }
      it { is_expected.to eq(Pathname('spec/models/foo_spec.rb')) }
    end

    context 'with file in parent directory' do
      let(:raw_path) { '/foo' }
      it { is_expected.to eq(Pathname('../foo')) }
    end

    context 'with file on another drive (e.g. Windows)' do
      let(:raw_path) { 'd:/project/foo' }
      let(:pathname) { instance_double(Pathname) }

      before do
        allow_any_instance_of(Pathname).to receive(:relative_path_from)
          .with(pwd).and_raise(ArgumentError)
      end

      it { is_expected.to eq(Pathname.new('d:/project/foo')) }
    end
  end

  describe '#relevant_changes?' do
    pending
  end
end
