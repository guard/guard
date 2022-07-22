# frozen_string_literal: true

require "guard/cli/environments/base"

RSpec.describe Guard::Cli::Environments::Base, :stub_ui do
  let(:no_bundler_warning) { false }
  let(:options) { { no_bundler_warning: no_bundler_warning } }

  shared_examples "avoids Bundler warning" do
    it "does not show the Bundler warning" do
      expect(Guard::UI).to_not have_received(:info).with(/Guard here!/)
    end
  end

  shared_examples "shows Bundler warning" do
    it "shows the Bundler warning" do
      expect(Guard::UI).to have_received(:info).with(/Guard here!/)
    end
  end

  subject { described_class.new(options) }

  describe "#bundler_check" do
    let(:gemdeps) { nil }
    let(:gemfile) { nil }

    before do
      allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return(gemfile)
      allow(ENV).to receive(:[]).with("RUBYGEMS_GEMDEPS").and_return(gemdeps)

      allow(File).to receive(:exist?).with("Gemfile")
                                     .and_return(gemfile_present)

      subject.__send__(:bundler_check)
    end

    context "without an existing Gemfile" do
      let(:gemfile_present) { false }

      include_examples "avoids Bundler warning"
    end

    context "with an existing Gemfile" do
      let(:gemfile_present) { true }

      context "with Bundler" do
        let(:gemdeps) { nil }
        let(:gemfile) { "Gemfile" }

        include_examples "avoids Bundler warning"
      end

      context "without Bundler" do
        let(:gemfile) { nil }

        context "with Rubygems Gemfile autodetection or custom Gemfile" do
          let(:gemdeps) { "-" }

          include_examples "avoids Bundler warning"
        end

        context "without Rubygems Gemfile handling" do
          let(:gemdeps) { nil }

          include_examples "shows Bundler warning"

          context "when options[:no_bundler_warning] == true" do
            let(:no_bundler_warning) { true }

            include_examples "avoids Bundler warning"
          end
        end
      end
    end
  end
end
