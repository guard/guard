require 'spec_helper'

describe Guard::Guardfile do

  let(:guardfile_generator) { double('Guard::Guardfile::Generator') }

  describe '.create_guardfile' do
    it 'displays a deprecation warning to the user' do
      ::Guard::UI.should_receive(:deprecation).with(::Guard::Deprecator::CREATE_GUARDFILE_DEPRECATION)

      described_class.create_guardfile
    end

    it 'delegates to Guard::Guardfile::Generator' do
      described_class::Generator.should_receive(:new).with(foo: 'bar') { guardfile_generator }
      guardfile_generator.should_receive(:create_guardfile)

      described_class.create_guardfile(foo: 'bar')
    end
  end

  describe '.initialize_template' do
    before do
      described_class::Generator.should_receive(:new) { guardfile_generator }
      guardfile_generator.stub(:initialize_template)
    end

    it 'displays a deprecation warning to the user' do
      ::Guard::UI.should_receive(:deprecation).with(::Guard::Deprecator::INITIALIZE_TEMPLATE_DEPRECATION)

      described_class.initialize_template('rspec')
    end

    it 'delegates to Guard::Guardfile::Generator' do
      guardfile_generator.should_receive(:initialize_template).with('rspec')

      described_class.initialize_template('rspec')
    end
  end

  describe '.initialize_all_templates' do
    before do
      described_class::Generator.should_receive(:new) { guardfile_generator }
      guardfile_generator.stub(:initialize_all_templates)
    end

    it 'displays a deprecation warning to the user' do
      ::Guard::UI.should_receive(:deprecation).with(::Guard::Deprecator::INITIALIZE_ALL_TEMPLATES_DEPRECATION)

      described_class.initialize_all_templates
    end

    it 'delegates to Guard::Guardfile::Generator' do
      guardfile_generator.should_receive(:initialize_all_templates)

      described_class.initialize_all_templates
    end
  end

end
