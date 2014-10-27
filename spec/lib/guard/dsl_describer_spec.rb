# encoding: utf-8
require "spec_helper"
require "guard/plugin"
require "guard/dsl_describer"
require "formatador"

describe Guard::DslDescriber do
  let(:interactor) { instance_double(Guard::Interactor) }

  let(:guardfile) do
    <<-GUARDFILE
      ignore! %r{tmp/}
      filter! %r{\.log}
      notification :gntp, sticky: true

      guard :test, a: :b, c: :d do
        watch('c')
      end

      group :a do
        guard 'test', x: 1, y: 2 do
          watch('c')
        end
      end

      group "b" do
        guard :another do
          watch('c')
        end
      end
    GUARDFILE
  end

  before do
    allow(Guard::Interactor).to receive(:new).and_return(interactor)
    allow(Guard::Notifier).to receive(:turn_on)
    allow(::Guard).to receive(:add_builtin_plugins)
    allow(Listen).to receive(:to).with(Dir.pwd, {})

    stub_const "Guard::Test", Class.new(Guard::Plugin)
    stub_const "Guard::Another", Class.new(Guard::Plugin)

    @output = ""

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
      allow(::Guard::PluginUtil).to receive(:plugin_names) do
        %w(test another even more)
      end
    end

    it "lists the available Guards declared as strings or symbols" do
      ::Guard::DslDescriber.new(guardfile_contents: guardfile).list
    end
  end

  describe ".show" do
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

    it "shows the Guards and their options" do
      ::Guard::DslDescriber.new(guardfile_contents: guardfile).show

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
      stub_const "Guard::Notifier::NOTIFIERS", [
        { gntp: ::Guard::Notifier::GNTP },
        { terminal_title: ::Guard::Notifier::TerminalTitle }
      ]

      allow(::Guard::Notifier::GNTP).to receive(:available?) { true }
      allow(::Guard::Notifier::TerminalTitle).to receive(:available?) { false }

      allow(::Guard::Notifier).to receive(:notifiers).and_return [
        { name: :gntp, options: { sticky: true } }
      ]
    end

    it "shows the notifiers and their options" do
      ::Guard::DslDescriber.new(guardfile_contents: guardfile).notifiers

      expect(@output).to eq result
    end
  end
end
