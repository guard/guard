require 'spec_helper'

describe Guard::Guardfile do

  it "has a valid Guardfile template" do
    File.exists?(Guard::GUARDFILE_TEMPLATE).should be_true
  end

  describe ".create_guardfile" do
    before { Dir.stub(:pwd).and_return "/home/user" }

    context "with an existing Guardfile" do
      before { File.should_receive(:exist?).and_return true }

      it "does not copy the Guardfile template or notify the user" do
        ::Guard::UI.should_not_receive(:info)
        FileUtils.should_not_receive(:cp)

        described_class.create_guardfile
      end

      it "does not display any kind of error or abort" do
        ::Guard::UI.should_not_receive(:error)
        described_class.should_not_receive(:abort)
        described_class.create_guardfile
      end

      context "with the :abort_on_existence option set to true" do
        it "displays an error message and aborts the process" do
          ::Guard::UI.should_receive(:error).with("Guardfile already exists at /home/user/Guardfile")
          described_class.should_receive(:abort)
          described_class.create_guardfile(:abort_on_existence => true)
        end
      end
    end

    context "without an existing Guardfile" do
      before { File.should_receive(:exist?).and_return false }

      it "copies the Guardfile template and notifies the user" do
        ::Guard::UI.should_receive(:info)
        FileUtils.should_receive(:cp)

        described_class.create_guardfile
      end
    end
  end

  describe ".initialize_template" do
    context 'with an installed Guard implementation' do
      let(:foo_guard) { double('Guard::Foo').as_null_object }

      before { ::Guard.should_receive(:get_guard_class).and_return(foo_guard) }

      it "initializes the Guard" do
        foo_guard.should_receive(:init)
        described_class.initialize_template('foo')
      end
    end

    context "with a user defined template" do
      let(:template) { File.join(Guard::HOME_TEMPLATES, '/bar') }

      before { File.should_receive(:exist?).with(template).and_return true }

      it "copies the Guardfile template and initializes the Guard" do
        File.should_receive(:read).with('Guardfile').and_return 'Guardfile content'
        File.should_receive(:read).with(template).and_return 'Template content'
        io = StringIO.new
        File.should_receive(:open).with('Guardfile', 'wb').and_yield io
        described_class.initialize_template('bar')
        io.string.should == "Guardfile content\n\nTemplate content\n"
      end
    end

    context "when the passed guard can't be found" do
      before do
        ::Guard.should_receive(:get_guard_class).and_return nil
        File.should_receive(:exist?).and_return false
      end

      it "notifies the user about the problem" do
        ::Guard::UI.should_receive(:error).with(
          "Could not load 'guard/foo' or '~/.guard/templates/foo' or find class Guard::Foo"
        )
        described_class.initialize_template('foo')
      end
    end
  end

  describe ".initialize_all_templates" do
    let(:guards) { ['rspec', 'spork', 'phpunit'] }

    before { ::Guard.should_receive(:guard_gem_names).and_return(guards) }

    it "calls Guard.initialize_template on all installed guards" do
      guards.each do |g|
        described_class.should_receive(:initialize_template).with(g)
      end

      described_class.initialize_all_templates
    end
  end

end
