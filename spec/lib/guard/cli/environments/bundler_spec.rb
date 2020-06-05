# frozen_string_literal: true

require "guard/cli/environments/bundler"

RSpec.shared_examples "avoids Bundler warning" do
  it "does not show the Bundler warning" do
    expect(Guard::UI).to_not have_received(:info).with(/Guard here!/)
  end
end

RSpec.shared_examples "shows Bundler warning" do
  it "shows the Bundler warning" do
    expect(Guard::UI).to have_received(:info).with(/Guard here!/)
  end
end

RSpec.describe Guard::Cli::Environments::Bundler, :stub_ui do
  describe "#verify" do
    let(:gemdeps) { nil }
    let(:gemfile) { nil }

    before do
      allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return(gemfile)
      allow(ENV).to receive(:[]).with("RUBYGEMS_GEMDEPS").and_return(gemdeps)

      allow(File).to receive(:exist?).with("Gemfile")
                                     .and_return(gemfile_present)

      subject.verify
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
        end
      end
    end
  end
end
