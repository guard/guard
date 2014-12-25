require "guard/notifier"

RSpec.describe Guard::Notifier::Base do
  let(:gntp) do
    double("GNTP notifier", name: "gntp", title: "GNTP", options: {})
  end

  let(:growl) do
    double("Growl notifier", name: "growl", title: "Growl", options: {})
  end

  module Guard
    module Notifier
      class FooBar < Notifier::Base
        def self.supported_hosts
          %w(freebsd solaris)
        end
      end
    end
  end

  before { allow(subject).to receive(:require) }

  describe ".name" do
    it 'un-modulizes the class, replaces "xY" with "x_Y" and downcase' do
      expect(Guard::Notifier::FooBar.name).to eq "foo_bar"
    end
  end

  describe "#name" do
    it "delegates to the class" do
      expect(Guard::Notifier::FooBar.new.name).
        to eq Guard::Notifier::FooBar.name
    end
  end

  describe ".title" do
    it "un-modulize the class" do
      expect(Guard::Notifier::FooBar.title).to eq "FooBar"
    end
  end

  describe "#title" do
    it "delegates to the class" do
      expect(Guard::Notifier::FooBar.new.title).
        to eq Guard::Notifier::FooBar.title
    end
  end

  describe ".normalize_standard_options!" do
    context "no opts given" do
      let(:opts) { {} }

      it "returns the Guard title image when no :title is defined" do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:title]).to eq "Guard"
      end

      it "returns the :success type when no :type is defined" do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:type]).to eq :success
      end

      it "returns the success.png image when no image is defined" do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:image]).to match(/success.png/)
      end
    end

    context ":title given" do
      let(:opts) { { title: "Hi" } }

      it "returns the passed :title" do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:title]).to eq "Hi"
      end
    end

    context "type: :foo given" do
      let(:opts) { { type: :foo } }

      it "returns the passed :type" do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:type]).to eq :foo
      end
    end

    context "image: nil given" do
      let(:opts) { { image: nil } }

      it 'sets the "notify" type' do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:type]).to eq :notify
        expect(opts[:image]).to be_nil
      end
    end

    context "image: :failed given" do
      let(:opts) { { image: :failed } }

      it 'sets the "failed" type' do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:image]).to match(/failed.png/)
      end
    end

    context "image: :pending given" do
      let(:opts) { { image: :pending } }

      it 'sets the "pending" type' do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:image]).to match(/pending.png/)
      end
    end

    context "image: :success given" do
      let(:opts) { { image: :success } }

      it 'sets the "success" type' do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:image]).to match(/success.png/)
      end
    end

    context 'image: "foo.png" given' do
      let(:opts) { { image: "foo.png" } }

      it 'sets the "success" type' do
        described_class.new.normalize_standard_options!(opts)

        expect(opts[:image]).to eq "foo.png"
      end
    end
  end

  describe ".available?" do
    context "without the silent option" do
      it "shows an error message when not available on the host OS" do
        expect(::Guard::UI).to receive(:error).
          with "The :foo_bar notifier runs only on FreeBSD, Solaris."

        expect(RbConfig::CONFIG).to receive(:[]).with("host_os") { "mswin" }

        Guard::Notifier::FooBar.available?
      end
    end
  end

  describe ".require_gem_safely" do
    context "library loads normally" do
      it "returns true" do
        expect(Guard::Notifier::FooBar).to receive(:require).with("foo_bar")

        expect(Guard::Notifier::FooBar.require_gem_safely).to be_truthy
      end
    end

    context "library fails to load" do
      it "shows an error message when the gem cannot be loaded" do
        expect(::Guard::UI).to receive(:error).
          with "Please add \"gem 'foo_bar'\" to your Gemfile"\
          " and run Guard with \"bundle exec\"."

        expect(Guard::Notifier::FooBar).to receive(:require).
          with("foo_bar").and_raise LoadError

        expect(Guard::Notifier::FooBar.require_gem_safely).to be_falsey
      end

      context "with the silent option" do
        it "does not show an error message when the gem cannot be loaded" do
          expect(::Guard::UI).to_not receive(:error).
            with "Please add \"gem 'growl_notify'\" to your Gemfile'\
            ' and run Guard with \"bundle exec\"."

          expect(Guard::Notifier::FooBar).to receive(:require).
            with("foo_bar").and_raise LoadError

          result = Guard::Notifier::FooBar.require_gem_safely(silent: true)
          expect(result).to be_falsey
        end
      end
    end
  end
end
