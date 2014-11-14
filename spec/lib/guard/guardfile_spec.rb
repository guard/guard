RSpec.describe Guard::Guardfile do

  let(:guardfile_generator) { instance_double(Guard::Guardfile::Generator) }

  describe ".create_guardfile" do
    before do
      allow(File).to receive(:exist?).with("Guardfile").and_return(false)
      template = Guard::Guardfile::Generator::GUARDFILE_TEMPLATE
      allow(FileUtils).to receive(:cp).with(template, "Guardfile")
    end

    it "displays a deprecation warning to the user" do
      expect(Guard::UI).to receive(:deprecation).
        with(Guard::Deprecator::CREATE_GUARDFILE_DEPRECATION)

      described_class.create_guardfile
    end

    it "delegates to Guard::Guardfile::Generator" do
      expect(described_class::Generator).to receive(:new).
        with(foo: "bar") { guardfile_generator }

      expect(guardfile_generator).to receive(:create_guardfile)

      described_class.create_guardfile(foo: "bar")
    end
  end

  describe ".initialize_template" do
    before do
      expect(described_class::Generator).to receive(:new) do
        guardfile_generator
      end

      allow(guardfile_generator).to receive(:initialize_template)
    end

    it "displays a deprecation warning to the user" do
      expect(Guard::UI).to receive(:deprecation).
        with(Guard::Deprecator::INITIALIZE_TEMPLATE_DEPRECATION)

      described_class.initialize_template("rspec")
    end

    it "delegates to Guard::Guardfile::Generator" do
      expect(guardfile_generator).to receive(:initialize_template).with("rspec")

      described_class.initialize_template("rspec")
    end
  end

  describe ".initialize_all_templates" do
    before do
      expect(described_class::Generator).to receive(:new) do
        guardfile_generator
      end

      allow(guardfile_generator).to receive(:initialize_all_templates)
    end

    it "displays a deprecation warning to the user" do
      expect(Guard::UI).to receive(:deprecation).
        with(Guard::Deprecator::INITIALIZE_ALL_TEMPLATES_DEPRECATION)

      described_class.initialize_all_templates
    end

    it "delegates to Guard::Guardfile::Generator" do
      expect(guardfile_generator).to receive(:initialize_all_templates)

      described_class.initialize_all_templates
    end
  end

end
