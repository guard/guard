# frozen_string_literal: true

require "guard/guardfile/generator"

RSpec.describe Guard::Guardfile::Generator do
  let!(:engine) { Guard.init }
  let(:plugin_util) { instance_double("Guard::PluginUtil") }

  subject { described_class.new(engine: engine) }

  before do
    stub_pathname
  end

  it "has a valid Guardfile template" do
    allow(File).to receive(:exist?)
      .with(described_class::GUARDFILE_TEMPLATE).and_call_original

    expect(File.exist?(described_class::GUARDFILE_TEMPLATE)).to be_truthy
  end

  describe "#create_guardfile" do
    context "with an existing Guardfile" do
      before do
        stub_guardfile("foo")
      end

      it "does not copy the Guardfile template or notify the user" do
        expect(::Guard::UI).to_not receive(:info)
        expect(FileUtils).to_not receive(:cp)
        begin
          subject.create_guardfile
        rescue SystemExit
        end
      end

      it "does not display information" do
        expect(::Guard::UI).to_not receive(:info)
        begin
          subject.create_guardfile
        rescue SystemExit
        end
      end

      it "displays an error message" do
        expect(::Guard::UI).to receive(:error)
          .with("Guardfile already exists at Guardfile")
        begin
          subject.create_guardfile
        rescue SystemExit
        end
      end

      it "aborts" do
        expect { subject.create_guardfile }.to raise_error(SystemExit)
      end
    end

    context "without an existing Guardfile" do
      before do
        stub_guardfile
        allow(FileUtils).to receive(:cp)
      end

      it "does not display any kind of error or abort" do
        expect(::Guard::UI).to_not receive(:error)
        expect(described_class).to_not receive(:abort)
        subject.create_guardfile
      end

      it "copies the Guardfile template and notifies the user" do
        expect(::Guard::UI).to receive(:info)
        expect(FileUtils).to receive(:cp)

        subject.create_guardfile
      end
    end
  end

  describe "#initialize_template" do
    before do
      @guardfile = stub_guardfile
    end

    context "with an installed Guard implementation" do
      before do
        expect(Guard::PluginUtil).to receive(:new) { plugin_util }
        expect(plugin_util).to receive(:plugin_class) do
          double("Guard::Foo").as_null_object
        end
      end

      it "initializes the Guard" do
        expect(plugin_util).to receive(:add_to_guardfile)
        subject.initialize_template("foo")
      end
    end

    context "with a user defined template" do
      let(:template) { File.join(described_class::HOME_TEMPLATES, "/bar") }
      let(:template_content) { "Template content" }

      before do
        stub_file("bar")
        stub_file(File.expand_path("~/.guard/templates/bar"), "Template content")
      end

      it "copies the Guardfile template and initializes the Guard" do
        expect(@guardfile).to receive(:binwrite)
          .with("\n#{template_content}\n", open_args: ["a"])
        expect(plugin_util).to receive(:plugin_class).with(fail_gracefully: true)
        expect(Guard::PluginUtil).to receive(:new).with(engine: engine, name: "bar")
                                                 .and_return(plugin_util)

        subject.initialize_template("bar")
      end
    end

    context "when the passed guard can't be found" do
      before do
        expect(::Guard::PluginUtil).to receive(:new) { plugin_util }
        allow(plugin_util).to receive(:plugin_class) { nil }
        stub_file("foo")
        stub_file(File.expand_path("~/.guard/templates/foo"))
      end

      it "notifies the user about the problem" do
        expect { subject.initialize_template("foo") }
          .to raise_error(Guard::Guardfile::Generator::Error)
      end
    end
  end

  describe "#initialize_all_templates" do
    let(:plugins) { %w[rspec spork phpunit] }

    before do
      expect(::Guard::PluginUtil).to receive(:plugin_names) { plugins }
    end

    it "calls Guard.initialize_template on all installed plugins" do
      plugins.each do |g|
        expect(subject).to receive(:initialize_template).with(g)
      end

      subject.initialize_all_templates
    end
  end
end
