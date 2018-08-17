# frozen_string_literal: true
require 'guard/config'

unless Guard::Config.new.strict?

  require 'guard/deprecated/guardfile'

  RSpec.describe Guard::Deprecated::Guardfile do
    subject do
      module TestModule; end.tap { |mod| described_class.add_deprecated(mod) }
    end

    let(:generator) { instance_double('Guard::Guardfile::Generator') }

    before do
      allow(Guard::UI).to receive(:deprecation)
    end

    describe '.create_guardfile' do
      before do
        allow(File).to receive(:exist?).with('Guardfile').and_return(false)
        template = Guard::Guardfile::Generator::GUARDFILE_TEMPLATE
        allow(FileUtils).to receive(:cp).with(template, 'Guardfile')

        allow(Guard::Guardfile::Generator).to receive(:new)
          .and_return(generator)

        allow(generator).to receive(:create_guardfile)
      end

      it 'displays a deprecation warning to the user' do
        expect(Guard::UI).to receive(:deprecation)
          .with(Guard::Deprecated::Guardfile::ClassMethods::CREATE_GUARDFILE)

        subject.create_guardfile
      end

      it 'delegates to Guard::Guardfile::Generator' do
        expect(Guard::Guardfile::Generator).to receive(:new)
          .with(foo: 'bar') { generator }

        expect(generator).to receive(:create_guardfile)

        subject.create_guardfile(foo: 'bar')
      end
    end

    describe '.initialize_template' do
      before do
        expect(Guard::Guardfile::Generator).to receive(:new) do
          generator
        end

        allow(generator).to receive(:initialize_template)
      end

      it 'displays a deprecation warning to the user' do
        expect(Guard::UI).to receive(:deprecation)
          .with(Guard::Deprecated::Guardfile::ClassMethods::INITIALIZE_TEMPLATE)

        subject.initialize_template('rspec')
      end

      it 'delegates to Guard::Guardfile::Generator' do
        expect(generator).to receive(:initialize_template).with('rspec')

        subject.initialize_template('rspec')
      end
    end

    describe '.initialize_all_templates' do
      before do
        expect(Guard::Guardfile::Generator).to receive(:new) do
          generator
        end

        allow(generator).to receive(:initialize_all_templates)
      end

      it 'displays a deprecation warning to the user' do
        expect(Guard::UI).to receive(:deprecation)
          .with(described_class::ClassMethods::INITIALIZE_ALL_TEMPLATES)

        subject.initialize_all_templates
      end

      it 'delegates to Guard::Guardfile::Generator' do
        expect(generator).to receive(:initialize_all_templates)

        subject.initialize_all_templates
      end
    end
  end
end
