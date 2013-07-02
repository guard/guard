require 'spec_helper'
require 'guard/cli'

describe Guard::CLI do
  let(:guard)         { Guard }
  let(:ui)            { Guard::UI }
  let(:dsl_describer) { double('DslDescriber instance') }

  describe '#start' do
    before { Guard.stub(:start) }

    it 'delegates to Guard.start' do
      Guard.should_receive(:start)

      subject.start
    end

    context 'with a Gemfile in the project dir' do
      before do
        File.stub(:exists?).with('Gemfile').and_return true
      end

      context 'when running with Bundler' do
        before do
          @bundler_env = ENV['BUNDLE_GEMFILE']
          ENV['BUNDLE_GEMFILE'] = 'Gemfile'
        end

        after { ENV['BUNDLE_GEMFILE'] = @bundler_env }

        it 'does not show the Bundler warning' do
          Guard::UI.should_not_receive(:info).with(/Guard here!/)
          subject.start
        end
      end

      context 'when running without Bundler' do
        before do
          @bundler_env = ENV['BUNDLE_GEMFILE']
          ENV['BUNDLE_GEMFILE'] = nil
        end

        after { ENV['BUNDLE_GEMFILE'] = @bundler_env }

        it 'does show the Bundler warning' do
          Guard::UI.should_receive(:info).with(/Guard here!/)
          subject.start
        end

        it 'does not show the Bundler warning with the :no_bundler_warning flag' do
          Guard::UI.should_not_receive(:info).with(/Guard here!/)
          subject.options = { :no_bundler_warning => true }
          subject.start
        end
      end
    end

    context 'without a Gemfile in the project dir' do
      before do
      File.should_receive(:exists?).with('Gemfile').and_return false
        @bundler_env = ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'] = nil
      end

      after { ENV['BUNDLE_GEMFILE'] = @bundler_env }

      it 'does not show the Bundler warning' do
        Guard::UI.should_not_receive(:info).with(/Guard here!/)
        subject.start
      end
    end
  end

  describe '#list' do
    it 'outputs the Guard plugins list' do
      ::Guard::DslDescriber.should_receive(:new) { dsl_describer }
      dsl_describer.should_receive(:list)

      subject.list
    end
  end

  describe '#version' do
    it 'shows the current version' do
      subject.should_receive(:puts).with(/#{ ::Guard::VERSION }/)

      subject.version
    end
  end

  describe '#init' do
    let(:options) { { :bare => false } }

    before do
      subject.stub(:options => options)
      Guard::Guardfile.stub(:create_guardfile)
      Guard::Guardfile.stub(:initialize_all_templates)
    end

    it 'creates a Guardfile by delegating to Guardfile.create_guardfile' do
      Guard::Guardfile.should_receive(:create_guardfile).with(:abort_on_existence => options[:bare])

      subject.init
    end

    it 'initializes the templates of all installed Guards by delegating to Guardfile.initialize_all_templates' do
      Guard::Guardfile.should_receive(:initialize_all_templates)

      subject.init
    end

    it 'initializes each passed template by delegating to Guardfile.initialize_template' do
      Guard::Guardfile.should_receive(:initialize_template).with('rspec')
      Guard::Guardfile.should_receive(:initialize_template).with('pow')

      subject.init 'rspec','pow'
    end

    context 'when passed a guard name' do
      it 'initializes the template of the passed Guard by delegating to Guardfile.initialize_template' do
        Guard::Guardfile.should_receive(:initialize_template).with('rspec')

        subject.init 'rspec'
      end
    end

    context 'with the bare option' do
      let(:options) { {:bare => true} }

      it 'Only creates the Guardfile and does not initialize any Guard template' do
        Guard::Guardfile.should_receive(:create_guardfile)
        Guard::Guardfile.should_not_receive(:initialize_template)
        Guard::Guardfile.should_not_receive(:initialize_all_templates)

        subject.init
      end
    end

    context 'when running with Bundler' do
      before do
        @bundler_env = ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'] = 'Gemfile'
      end

      after { ENV['BUNDLE_GEMFILE'] = @bundler_env }

      it 'does not show the Bundler warning' do
        Guard::UI.should_not_receive(:info).with(/Guard here!/)

        subject.init
      end
    end

    context 'when running without Bundler' do
      before do
        @bundler_env = ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'] = nil
      end

      after { ENV['BUNDLE_GEMFILE'] = @bundler_env }

      it 'does not show the Bundler warning' do
        Guard::UI.should_receive(:info).with(/Guard here!/)

        subject.init
      end
    end
  end

  describe '#show' do
    it 'outputs the Guard::DslDescriber.list result' do
      ::Guard::DslDescriber.should_receive(:new) { dsl_describer }
      dsl_describer.should_receive(:show)

      subject.show
    end
  end
end
