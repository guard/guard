require 'spec_helper'

describe Guard::Notifier::Nsnotify do
  before(:all) { Object.send(:remove_const, :Nsnotify) if defined?(::Nsnotify) }

  before do
    subject.stub(:require)

    class ::Nsnotify
      def self.show(options) end
    end
  end

  after { Object.send(:remove_const, :Nsnotify) if defined?(::Nsnotify) }

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :nsnotify notifier only runs on Mac OS X 10.8 and later.'
        ::Nsnotify.stub(:usable?).and_return(false)
        subject.available?
      end
    end
  end

  describe ".notify" do
    it "should call the notifier." do
      ::Nsnotify.should_receive(:notify).with(
        "Guard Success any title",
        "any message"
      )
      subject.notify('success', 'any title', 'any message', 'any image', { })
    end

    it "should show the type of message in the title" do
      ::Nsnotify.should_receive(:notify).with(
        "FooBar Error any title",
        "any message"
      )

      subject.notify('error', 'any title', 'any message', 'any image', {:app_name => "FooBar"})
    end

    context "with an app name set" do
      it "should show the app name in the title" do
        ::Nsnotify.should_receive(:notify).with(
          "FooBar Success any title",
          "any message"
        )

        subject.notify('success', 'any title', 'any message', 'any image', {:app_name => "FooBar"})
      end
    end
  end
end
