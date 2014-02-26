require 'spec_helper'
require 'guard/cli'

describe Guard::CLI do
  let(:guard)         { Guard }
  let(:ui)            { Guard::UI }
  let(:dsl_describer) { double('DslDescriber instance') }

  describe '#start' do
    before { allow(Guard).to receive(:start) }

    it 'delegates to Guard.start' do
      expect(Guard).to receive(:start)

      subject.start
    end

    context 'with a Gemfile in the project dir' do
      before do
        allow(File).to receive(:exists?).with('Gemfile').and_return(true)
      end

      context 'when running with Bundler' do
        before do
          @bundler_env = ENV['BUNDLE_GEMFILE']
          ENV['BUNDLE_GEMFILE'] = 'Gemfile'
        end

        after { ENV['BUNDLE_GEMFILE'] = @bundler_env }

        it 'does not show the Bundler warning' do
          expect(Guard::UI).to_not receive(:info).with(/Guard here!/)
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
          expect(Guard::UI).to receive(:info).with(/Guard here!/)
          subject.start
        end

        it 'does not show the Bundler warning with the :no_bundler_warning flag' do
          expect(Guard::UI).to_not receive(:info).with(/Guard here!/)
          subject.options = { no_bundler_warning: true }
          subject.start
        end
      end
    end

    context 'without a Gemfile in the project dir' do
      before do
      expect(File).to receive(:exists?).with('Gemfile').and_return false
        @bundler_env = ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'] = nil
      end

      after { ENV['BUNDLE_GEMFILE'] = @bundler_env }

      it 'does not show the Bundler warning' do
        expect(Guard::UI).to_not receive(:info).with(/Guard here!/)
        subject.start
      end
    end
  end

  describe '#list' do
    it 'outputs the Guard plugins list' do
      expect(::Guard::DslDescriber).to receive(:new) { dsl_describer }
      expect(dsl_describer).to receive(:list)

      subject.list
    end
  end

  describe '#notifiers' do
    it 'outputs the notifiers list' do
      expect(::Guard::DslDescriber).to receive(:new) { dsl_describer }
      expect(dsl_describer).to receive(:notifiers)

      subject.notifiers
    end
  end

  describe '#version' do
    it 'shows the current version' do
      expect(subject).to receive(:puts).with(/#{ ::Guard::VERSION }/)

      subject.version
    end
  end

  describe '#init' do
    let(:options) { { bare: false } }

    before do
      allow(subject).to receive(:options).and_return(options)
      allow(Guard::Guardfile).to receive(:create_guardfile)
      allow(Guard::Guardfile).to receive(:initialize_all_templates)
    end

    it 'creates a Guardfile by delegating to Guardfile.create_guardfile' do
      expect(Guard::Guardfile).to receive(:create_guardfile).with(abort_on_existence: options[:bare])

      subject.init
    end

    it 'initializes the templates of all installed Guards by delegating to Guardfile.initialize_all_templates' do
      expect(Guard::Guardfile).to receive(:initialize_all_templates)

      subject.init
    end

    it 'initializes each passed template by delegating to Guardfile.initialize_template' do
      expect(Guard::Guardfile).to receive(:initialize_template).with('rspec')
      expect(Guard::Guardfile).to receive(:initialize_template).with('pow')

      subject.init 'rspec','pow'
    end

    context 'when passed a guard name' do
      it 'initializes the template of the passed Guard by delegating to Guardfile.initialize_template' do
        expect(Guard::Guardfile).to receive(:initialize_template).with('rspec')

        subject.init 'rspec'
      end
    end

    context 'with the bare option' do
      let(:options) { {bare: true} }

      it 'Only creates the Guardfile and does not initialize any Guard template' do
        expect(Guard::Guardfile).to receive(:create_guardfile)
        expect(Guard::Guardfile).to_not receive(:initialize_template)
        expect(Guard::Guardfile).to_not receive(:initialize_all_templates)

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
        expect(Guard::UI).to_not receive(:info).with(/Guard here!/)

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
        expect(Guard::UI).to receive(:info).with(/Guard here!/)

        subject.init
      end
    end
  end

  describe '#show' do
    it 'outputs the Guard::DslDescriber.list result' do
      expect(::Guard::DslDescriber).to receive(:new) { dsl_describer }
      expect(dsl_describer).to receive(:show)

      subject.show
    end
  end
end
