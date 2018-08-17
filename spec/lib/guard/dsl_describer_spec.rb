# frozen_string_literal: true

require 'guard/plugin'
require 'guard/dsl_describer'
require 'formatador'

RSpec.describe Guard::DslDescriber do
  let(:interactor) { instance_double(Guard::Interactor) }
  let(:env) { double('ENV') }

  let(:session) { instance_double('Guard::Internals::Session') }
  let(:plugins) { instance_double('Guard::Internals::Plugins') }
  let(:groups) { instance_double('Guard::Internals::Groups') }
  let(:state) { instance_double('Guard::Internals::State') }

  before do
    allow(session).to receive(:groups).and_return(groups)
    allow(session).to receive(:plugins).and_return(plugins)
    allow(state).to receive(:session).and_return(session)
    allow(Guard).to receive(:state).and_return(state)

    allow(env).to receive(:[]).with('GUARD_NOTIFY_PID')
    allow(env).to receive(:[]).with('GUARD_NOTIFY')
    allow(env).to receive(:[]).with('GUARD_NOTIFIERS')
    allow(env).to receive(:[]=).with('GUARD_NOTIFIERS', anything)

    allow(Guard::Notifier).to receive(:turn_on)

    stub_const 'Guard::Test', class_double('Guard::Plugin')
    stub_const 'Guard::Another', class_double('Guard::Plugin')

    @output = +''

    # Strip escape sequences
    allow(STDOUT).to receive(:tty?).and_return(false)

    # Capture formatador output
    Thread.current[:formatador] = Formatador.new
    allow(Thread.current[:formatador]).to receive(:print) do |msg|
      @output << msg
    end
  end

  describe '#list' do
    let(:result) do
      <<-OUTPUT
  +---------+-----------+
  | Plugin  | Guardfile |
  +---------+-----------+
  | Another | ✔         |
  | Even    | ✘         |
  | More    | ✘         |
  | Test    | ✔         |
  +---------+-----------+
      OUTPUT
    end

    let(:another) { instance_double('Guard::Plugin', title: 'Another') }
    let(:test) { instance_double('Guard::Plugin', title: 'Test') }

    before do
      allow(plugins).to receive(:all).with('another').and_return([another])
      allow(plugins).to receive(:all).with('test').and_return([test])
      allow(plugins).to receive(:all).with('even').and_return([])
      allow(plugins).to receive(:all).with('more').and_return([])

      allow(Guard::PluginUtil).to receive(:plugin_names) do
        %w[test another even more]
      end
    end

    it 'lists the available Guards declared as strings or symbols' do
      subject.list
      expect(@output).to eq result
    end
  end

  describe '.show' do
    let(:result) do
      <<-OUTPUT
  +---------+---------+--------+-------+
  | Group   | Plugin  | Option | Value |
  +---------+---------+--------+-------+
  | Default | Test    | a      | :b    |
  |         |         | c      | :d    |
  +---------+---------+--------+-------+
  | A       | Test    | x      | 1     |
  |         |         | y      | 2     |
  +---------+---------+--------+-------+
  | B       | Another |        |       |
  +---------+---------+--------+-------+
      OUTPUT
    end

    before do
      allow(groups).to receive(:all).and_return [
        instance_double('Guard::Group', name: :default, title: 'Default'),
        instance_double('Guard::Group', name: :a, title: 'A'),
        instance_double('Guard::Group', name: :b, title: 'B')
      ]

      allow(plugins).to receive(:all).with(group: :default) do
        options = { a: :b, c: :d }
        [instance_double('Guard::Plugin', title: 'Test', options: options)]
      end

      allow(plugins).to receive(:all).with(group: :a) do
        options = { x: 1, y: 2 }
        [instance_double('Guard::Plugin', title: 'Test', options: options)]
      end

      allow(plugins).to receive(:all).with(group: :b).and_return [
        instance_double('Guard::Plugin', title: 'Another', options: [])
      ]
    end

    it 'shows the Guards and their options' do
      subject.show
      expect(@output).to eq result
    end
  end

  describe '.notifiers' do
    let(:result) do
      <<-OUTPUT
  +----------------+-----------+------+--------+-------+
  | Name           | Available | Used | Option | Value |
  +----------------+-----------+------+--------+-------+
  | gntp           | ✔         | ✔    | sticky | true  |
  +----------------+-----------+------+--------+-------+
  | terminal_title | ✘         | ✘    |        |       |
  +----------------+-----------+------+--------+-------+
      OUTPUT
    end

    before do
      allow(Guard::Notifier).to receive(:supported).and_return(
        gntp: ::Notiffany::Notifier::GNTP,
        terminal_title: ::Notiffany::Notifier::TerminalTitle
      )

      allow(Guard::Notifier).to receive(:connect).once
      allow(Guard::Notifier).to receive(:detected)
        .and_return([{ name: :gntp, options: { sticky: true } }])

      allow(Guard::Notifier).to receive(:disconnect).once
    end

    it 'properly connects and disconnects' do
      expect(Guard::Notifier).to receive(:connect).once.ordered
      expect(::Guard::Notifier).to receive(:detected).once.ordered.and_return [
        { name: :gntp, options: { sticky: true } }
      ]

      expect(Guard::Notifier).to receive(:disconnect).once.ordered

      subject.notifiers
    end

    it 'shows the notifiers and their options' do
      subject.notifiers
      expect(@output).to eq result
    end
  end
end
