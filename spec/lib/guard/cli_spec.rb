# frozen_string_literal: true

require "guard/cli"

RSpec.describe Guard::CLI do
  include_context "Guard options"

  let(:write_environment) { instance_double("Guard::Cli::Environments::Write") }
  let(:read_only_environment) do
    instance_double("Guard::Cli::Environments::ReadOnly")
  end
  let(:dsl_describer) { instance_double("Guard::DslDescriber") }

  before do
    allow(subject).to receive(:options).and_return(options)
    allow(Guard::DslDescriber).to receive(:new).and_return(dsl_describer)
    allow(Guard::Cli::Environments::ReadOnly).to receive(:new).with(options).and_return(read_only_environment)
    allow(Guard::Cli::Environments::Write).to receive(:new).with(options).and_return(write_environment)
  end

  describe "#start" do
    before do
      allow(read_only_environment).to receive(:start).and_return(0)
    end

    it "delegates to Guard::Environment.start" do
      expect(read_only_environment).to receive(:start).and_return(0)

      begin
        subject.start
      rescue SystemExit
      end
    end

    it "exits with given exit code" do
      allow(read_only_environment).to receive(:start).and_return(4)

      expect { subject.start }.to raise_error(SystemExit) do |exception|
        expect(exception.status).to eq(4)
        exception
      end
    end

    it "passes options" do
      expect(Guard::Cli::Environments::ReadOnly)
        .to receive(:new)
        .with(options)
        .and_return(read_only_environment)

      begin
        subject.start
      rescue SystemExit
      end
    end
  end

  describe "#list" do
    before do
      allow(read_only_environment).to receive(:evaluate).and_return(read_only_environment)
      allow(dsl_describer).to receive(:list)
      subject.list
    end

    it "calls the evaluation" do
      expect(read_only_environment).to have_received(:evaluate)
    end

    it "outputs the Guard plugins list" do
      expect(dsl_describer).to have_received(:list)
    end
  end

  describe "#notifiers" do
    before do
      allow(read_only_environment).to receive(:evaluate).and_return(read_only_environment)
      allow(dsl_describer).to receive(:notifiers)

      subject.notifiers
    end

    it "calls the evaluation" do
      expect(read_only_environment).to have_received(:evaluate)
    end

    it "outputs the notifiers list" do
      expect(dsl_describer).to have_received(:notifiers)
    end
  end

  describe "#version" do
    it "shows the current version" do
      expect(STDOUT).to receive(:puts).with(/#{::Guard::VERSION}/)
      subject.version
    end
  end

  describe "#init" do
    before do
      allow(Guard::Cli::Environments::Write).to receive(:new)
        .and_return(write_environment)
      allow(write_environment).to receive(:initialize_guardfile).and_return(0)
    end

    it "exits with given exit code" do
      allow(write_environment).to receive(:initialize_guardfile).and_return(4)

      expect { subject.init }.to raise_error(SystemExit) do |exception|
        expect(exception.status).to eq(4)
      end
    end

    it "passes options" do
      expect(Guard::Cli::Environments::Write).to receive(:new).with(options)
                                                              .and_return(write_environment)
      begin
        subject.init
      rescue SystemExit
      end
    end

    it "passes plugin names" do
      plugins = [double("plugin1"), double("plugin2")]

      expect(write_environment).to receive(:initialize_guardfile).with(plugins)

      begin
        subject.init(*plugins)
      rescue SystemExit
      end
    end
  end

  describe "#show" do
    before do
      allow(read_only_environment).to receive(:evaluate).and_return(read_only_environment)
      allow(dsl_describer).to receive(:show)

      subject.show
    end

    it "calls the evaluation" do
      expect(read_only_environment).to have_received(:evaluate)
    end

    it "outputs the Guard::DslDescriber.list result" do
      expect(dsl_describer).to have_received(:show)
    end
  end
end
