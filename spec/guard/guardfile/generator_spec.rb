require 'spec_helper'

describe Guard::Guardfile::Generator do

  let(:plugin_util) { double('Guard::PluginUtil') }
  let(:guardfile_generator) { described_class.new }

  it "has a valid Guardfile template" do
    File.exists?(described_class::GUARDFILE_TEMPLATE).should be_true
  end

  describe '#create_guardfile' do
    before { Dir.stub(:pwd).and_return "/home/user" }

    context "with an existing Guardfile" do
      before { File.should_receive(:exist?).and_return true }

      it "does not copy the Guardfile template or notify the user" do
        ::Guard::UI.should_not_receive(:info)
        FileUtils.should_not_receive(:cp)

        described_class.new.create_guardfile
      end

      it "does not display any kind of error or abort" do
        ::Guard::UI.should_not_receive(:error)
        described_class.should_not_receive(:abort)
        described_class.new.create_guardfile
      end

      context "with the :abort_on_existence option set to true" do
        it "displays an error message and aborts the process" do
          guardfile_generator = described_class.new(:abort_on_existence => true)
          ::Guard::UI.should_receive(:error).with("Guardfile already exists at /home/user/Guardfile")
          guardfile_generator.should_receive(:abort)

          guardfile_generator.create_guardfile
        end
      end
    end

    context "without an existing Guardfile" do
      before { File.should_receive(:exist?).and_return false }

      it "copies the Guardfile template and notifies the user" do
        ::Guard::UI.should_receive(:info)
        FileUtils.should_receive(:cp)

        described_class.new.create_guardfile
      end
    end
  end

  describe '#initialize_template' do
    context 'with an installed Guard implementation' do
      before do
        ::Guard::PluginUtil.should_receive(:new) { plugin_util }
        plugin_util.should_receive(:plugin_class) { double('Guard::Foo').as_null_object }
      end

      it 'initializes the Guard' do
        plugin_util.should_receive(:add_to_guardfile)
        described_class.new.initialize_template('foo')
      end
    end

    context "with a user defined template" do
      let(:template) { File.join(described_class::HOME_TEMPLATES, '/bar') }

      before { File.should_receive(:exist?).with(template).and_return true }

      it "copies the Guardfile template and initializes the Guard" do
        File.should_receive(:read).with('Guardfile').and_return 'Guardfile content'
        File.should_receive(:read).with(template).and_return 'Template content'
        io = StringIO.new
        File.should_receive(:open).with('Guardfile', 'wb').and_yield io
        described_class.new.initialize_template('bar')
        io.string.should eq "Guardfile content\n\nTemplate content\n"
      end
    end

    context "when the passed guard can't be found" do
      before do
        ::Guard::PluginUtil.should_receive(:new) { plugin_util }
        plugin_util.stub!(:plugin_class) { nil }
        File.should_receive(:exist?).and_return false
      end

      it "notifies the user about the problem" do
        ::Guard::UI.should_receive(:error).with(
          "Could not load 'guard/foo' or '~/.guard/templates/foo' or find class Guard::Foo"
        )
        described_class.new.initialize_template('foo')
      end
    end
  end

  describe '#initialize_all_templates' do
    let(:plugins) { ['rspec', 'spork', 'phpunit'] }

    before { ::Guard::PluginUtil.should_receive(:plugin_names).and_return(plugins) }

    it "calls Guard.initialize_template on all installed plugins" do
      guardfile_generator = described_class.new
      plugins.each do |g|
        guardfile_generator.should_receive(:initialize_template).with(g)
      end

      guardfile_generator.initialize_all_templates
    end
  end

end
