require 'spec_helper'

describe Guard::Guardfile::Generator do

  let(:plugin_util) { double('Guard::PluginUtil') }
  let(:guardfile_generator) { described_class.new }

  it "has a valid Guardfile template" do
    expect(File.exists?(described_class::GUARDFILE_TEMPLATE)).to be_truthy
  end

  describe '#create_guardfile' do
    before { Dir.stub(:pwd).and_return "/home/user" }

    context "with an existing Guardfile" do
      before { expect(File).to receive(:exist?) { true } }

      it "does not copy the Guardfile template or notify the user" do
        expect(::Guard::UI).to_not receive(:info)
        expect(FileUtils).to_not receive(:cp)

        described_class.new.create_guardfile
      end

      it "does not display any kind of error or abort" do
        expect(::Guard::UI).to_not receive(:error)
        expect(described_class).to_not receive(:abort)
        described_class.new.create_guardfile
      end

      context "with the :abort_on_existence option set to true" do
        it "displays an error message and aborts the process" do
          guardfile_generator = described_class.new(abort_on_existence: true)
          expect(::Guard::UI).to receive(:error).with("Guardfile already exists at /home/user/Guardfile")
          expect(guardfile_generator).to receive(:abort)

          guardfile_generator.create_guardfile
        end
      end
    end

    context "without an existing Guardfile" do
      before { expect(File).to receive(:exist?) { false } }

      it "copies the Guardfile template and notifies the user" do
        expect(::Guard::UI).to receive(:info)
        expect(FileUtils).to receive(:cp)

        described_class.new.create_guardfile
      end
    end
  end

  describe '#initialize_template' do
    context 'with an installed Guard implementation' do
      before do
        expect(::Guard::PluginUtil).to receive(:new) { plugin_util }
        expect(plugin_util).to receive(:plugin_class) { double('Guard::Foo').as_null_object }
      end

      it 'initializes the Guard' do
        expect(plugin_util).to receive(:add_to_guardfile)
        described_class.new.initialize_template('foo')
      end
    end

    context "with a user defined template" do
      let(:template) { File.join(described_class::HOME_TEMPLATES, '/bar') }

      before { expect(File).to receive(:exist?).with(template) { true } }

      it "copies the Guardfile template and initializes the Guard" do
        expect(File).to receive(:read).with('Guardfile').and_return 'Guardfile content'
        expect(File).to receive(:read).with(template).and_return 'Template content'
        io = StringIO.new
        expect(File).to receive(:open).with('Guardfile', 'wb').and_yield io
        described_class.new.initialize_template('bar')
        expect(io.string).to eq "Guardfile content\n\nTemplate content\n"
      end
    end

    context "when the passed guard can't be found" do
      before do
        expect(::Guard::PluginUtil).to receive(:new) { plugin_util }
        plugin_util.stub(:plugin_class) { nil }
        expect(File).to receive(:exist?).and_return false
      end

      it "notifies the user about the problem" do
        expect(::Guard::UI).to receive(:error).with(
          "Could not load 'guard/foo' or '~/.guard/templates/foo' or find class Guard::Foo"
        )
        described_class.new.initialize_template('foo')
      end
    end
  end

  describe '#initialize_all_templates' do
    let(:plugins) { ['rspec', 'spork', 'phpunit'] }

    before { expect(::Guard::PluginUtil).to receive(:plugin_names) { plugins } }

    it "calls Guard.initialize_template on all installed plugins" do
      guardfile_generator = described_class.new
      plugins.each do |g|
        expect(guardfile_generator).to receive(:initialize_template).with(g)
      end

      guardfile_generator.initialize_all_templates
    end
  end

end
