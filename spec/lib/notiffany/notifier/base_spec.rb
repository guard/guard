require "notiffany/notifier/base"

# TODO: no point in testing the base class, really
RSpec.describe Notiffany::Notifier::Base do
  let(:ui) { double("UI") }
  let(:fake) { double ("fake_lib") }
  let(:options) { {} }
  subject { Notiffany::Notifier::FooBar.new(ui, { fake: fake }.merge(options)) }

  before do
    allow(Kernel).to receive(:require)
  end

  module Notiffany
    module Notifier
      class FooBar < Notifier::Base
        DEFAULTS = { foo: :bar }

        def supported_hosts
          %w(freebsd solaris)
        end

        def _perform_notify(message, options)
          options[:fake].notify(message, options)
        end

        def available?
          super && require_gem_safely
        end
      end
    end
  end

  describe "#name" do
    it 'un-modulizes the class, replaces "xY" with "x_Y" and downcase' do
      expect(subject.name).to eq "foo_bar"
    end
  end

  describe "#title" do
    it "un-modulize the class" do
      expect(subject.title).to eq "FooBar"
    end
  end

  describe "#notify" do
    let(:opts) { {} }

    context "with no notify title overrides" do
      it "supplies default title" do
        expect(fake).to receive(:notify).
          with("foo", hash_including(title: "Notiffany"))
        subject.notify("foo", opts)
      end
    end

    context "with notify title override" do
      let(:opts) { { title: "Hi" } }
      it "uses given title" do
        expect(fake).to receive(:notify).
          with("foo", hash_including(title: "Hi"))
        subject.notify("foo", opts)
      end
    end

    context "with no type overrides" do
      it "supplies default type" do
        expect(fake).to receive(:notify).
          with("foo", hash_including(type: :success))
        subject.notify("foo", opts)
      end
    end

    context "with type given" do
      let(:opts) { { type: :foo } }
      it "uses given type" do
        expect(fake).to receive(:notify).
          with("foo", hash_including(type: :foo))
        subject.notify("foo", opts)
      end
    end

    context "with no image overrides" do
      it "supplies default image" do
        expect(fake).to receive(:notify).
          with("foo", hash_including(image: /success.png$/))
        subject.notify("foo", opts)
      end
    end

    %w(failed pending success guard).each do |img|
      context "with #{img.to_sym.inspect} image" do
        let(:opts) { { image: img.to_sym } }
        it "converts to image path" do
          expect(fake).to receive(:notify).
            with("foo", hash_including(image: /#{img}.png$/))
          subject.notify("foo", opts)
        end
      end
    end

    context "with a custom image" do
      let(:opts) { { image: "foo.jpg" } }
      it "uses given image" do
        expect(fake).to receive(:notify).
          with("foo", hash_including(image: "foo.jpg"))
        subject.notify("foo", opts)
      end
    end

    context "with nil image" do
      let(:opts) { { image: nil } }
      it "set the notify image to nil" do
        expect(fake).to receive(:notify).
          with("foo", hash_including(image: nil))
        subject.notify("foo", opts)
      end

      it "uses the default type" do
        expect(fake).to receive(:notify).
          with("foo", hash_including(type: :notify))
        subject.notify("foo", opts)
      end
    end

  end

  describe ".available?" do
    before do
      expect(RbConfig::CONFIG).to receive(:[]).with("host_os") { os }
    end

    context "on unsupported os" do
      let(:os) { "mswin" }
      context "without the silent option" do
        it "shows an error message when not available on the host OS" do
          expect(ui).to receive(:error).
            with "The :foo_bar notifier runs only on FreeBSD, Solaris."
          subject.available?
        end
      end
    end

    context "on supported os" do
      let(:os) { "freebsd" }

      context "library loads normally" do
        it "returns true" do
          expect(Kernel).to receive(:require).with("foo_bar")
          expect(subject).to be_available
        end
      end

      context "when library fails to load" do
        before do
          allow(Kernel).to receive(:require).with("foo_bar").
            and_raise LoadError
          allow(ui).to receive(:error)
        end

        it { is_expected.to_not be_available }

        context "without the silent option" do
          it "shows an error message when the gem cannot be loaded" do
            expect(ui).to receive(:error).
              with "Please add \"gem 'foo_bar'\" to your Gemfile"\
              " and run your app with \"bundle exec\"."

            subject.available?
          end
        end

        context "with the silent option" do
          let(:options) { { silent: true } }
          it "does not show an error message when the gem cannot be loaded" do
            expect(ui).to_not receive(:error)
            subject.available?
          end
        end
      end
    end
  end
end
