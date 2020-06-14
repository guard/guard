# frozen_string_literal: true

require "guard/dsl_describer"
require "guard/guardfile/result"

RSpec.describe Guard::DslDescriber, :stub_ui do
  let(:guardfile_result) { Guard::Guardfile::Result.new }
  let(:interactor) { instance_double(Guard::Interactor) }
  let(:env) { double("ENV") }

  subject { described_class.new(guardfile_result) }

  before do
    guardfile_result.plugins << [:another, {}] << [:test, {}]
    allow(env).to receive(:[]).with("GUARD_NOTIFY_PID")
    allow(env).to receive(:[]).with("GUARD_NOTIFY")
    allow(env).to receive(:[]).with("GUARD_NOTIFIERS")
    allow(env).to receive(:[]=).with("GUARD_NOTIFIERS", anything)

    allow(Guard::Notifier).to receive(:turn_on)

    @output = +""

    # Strip escape sequences
    allow(STDOUT).to receive(:tty?).and_return(false)

    # Capture formatador output
    Thread.current[:formatador] = Formatador.new
    allow(Thread.current[:formatador]).to receive(:print) do |msg|
      @output << msg
    end
  end

  describe "#list" do
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

    before do
      allow(Guard::PluginUtil).to receive(:plugin_names) do
        %w[test another even more]
      end
    end

    it "lists the available Guards declared as strings or symbols" do
      subject.list
      expect(@output).to eq result
    end
  end

  describe ".show" do
    let(:result) do
      <<-OUTPUT
  +---------+---------+--------+-------+
  | Group   | Plugin  | Option | Value |
  +---------+---------+--------+-------+
  | default | test    | a      | :b    |
  |         |         | c      | :d    |
  +---------+---------+--------+-------+
  | a       | test    | x      | 1     |
  |         |         | y      | 2     |
  +---------+---------+--------+-------+
  | b       | another |        |       |
  +---------+---------+--------+-------+
      OUTPUT
    end

    before do
      guardfile_result.groups.merge!(default: {}, a: {}, b: {})
      guardfile_result.plugins << [:test, { a: :b, c: :d, group: :default }]
      guardfile_result.plugins << [:test, { x: 1, y: 2, group: :a }]
      guardfile_result.plugins << [:another, { group: :b }]
    end

    it "shows the Guards and their options" do
      subject.show
      expect(@output).to eq result
    end
  end

  describe ".notifiers" do
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

    it "properly connects and disconnects" do
      expect(Guard::Notifier).to receive(:connect).once.ordered
      expect(::Guard::Notifier).to receive(:detected).once.ordered.and_return [
        { name: :gntp, options: { sticky: true } }
      ]

      expect(Guard::Notifier).to receive(:disconnect).once.ordered

      subject.notifiers
    end

    it "shows the notifiers and their options" do
      subject.notifiers
      expect(@output).to eq result
    end
  end
end
