require 'spec_helper'

describe Guard::Notifier::TerminalNotifier do
  before(:all) { Object.send(:remove_const, :TerminalNotifier) if defined?(::TerminalNotifier) }

  before do
    subject.stub(:require)

    class TerminalNotifier
      module Guard
        def self.show(options) end
      end
    end
  end

  after { Object.send(:remove_const, :TerminalNotifier) if defined?(::TerminalNotifier) }

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :terminal_notifier only runs on Mac OS X 10.8 and later.'
        ::TerminalNotifier::Guard.stub(:available?).and_return(false)
        subject.available?
      end
    end
  end

  describe ".notify" do
    it "should call the notifier." do
      ::TerminalNotifier::Guard.should_receive(:execute).with(
        false,
        {:title=>"Guard Success any title", :type=>:success, :message=>"any message"}
      )
      subject.notify('success', 'any title', 'any message', 'any image', { })
    end

    it "should show the type of message in the title" do
      ::TerminalNotifier::Guard.should_receive(:execute).with(
        false,
        {:title=>"Guard Error any title", :message => "any message", :type => :error}
      )

      subject.notify('error', 'any title', 'any message', 'any image', { })
    end

    context "with an app name set" do
      it "should show the app name in the title" do
        ::TerminalNotifier::Guard.should_receive(:execute).with(
          false,
          {:title=>"FooBar Success any title", :type=>:success, :message=>"any message"}
        )

        subject.notify('success', 'any title', 'any message', 'any image', {:app_name => "FooBar"})
      end
    end
  end
end
