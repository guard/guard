require 'spec_helper'

describe Guard::Notifier::Tmux do
  before(:all) { Object.send(:remove_const, :Tmux) if defined?(::Tmux) }

  before do
    class ::Tmux
      def self.show(options) end
    end
  end

  after { Object.send(:remove_const, :Tmux) if defined?(::Tmux) }

  describe '.available?' do
    context "when the TMUX environment variable is set" do
      before :each do
        ENV['TMUX'] = 'something'
      end

      it "should return true" do
        subject.available?.should be_true
      end
    end

    context "when the TMUX environment variable is not set" do
      before :each do
        ENV['TMUX'] = nil
      end

      context 'without the silent option' do
        it 'shows an error message when the TMUX environment variable is not set' do
          ::Guard::UI.should_receive(:error).with "The :tmux notifier runs only on when Guard is executed inside of a tmux session."
          subject.available?
        end
      end

      context 'with the silent option' do
        it 'should return false' do
          subject.available?(true).should be_false
        end
      end
    end
  end

  describe '.notify' do
    it 'should set the tmux status bar color to green on success' do
      subject.should_receive(:system).with "tmux set -g status-left-bg green"

      subject.notify('success', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to black on success when black is passed in as an option' do
      subject.should_receive(:system).with "tmux set -g status-left-bg black"

      subject.notify('success', 'any title', 'any message', 'any image', { :success => 'black' })
    end

    it 'should set the tmux status bar color to red on failure' do
      subject.should_receive(:system).with "tmux set -g status-left-bg red"

      subject.notify('failed', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to yellow on pending' do
      subject.should_receive(:system).with "tmux set -g status-left-bg yellow"

      subject.notify('pending', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to green on notify' do
      subject.should_receive(:system).with "tmux set -g status-left-bg green"

      subject.notify('notify', 'any title', 'any message', 'any image', { })
    end

    it 'calls display_message if the display_message flag is set' do
      subject.stub :system => true
      subject.should_receive(:display_message).with('notify', 'any title', 'any message', { :display_message => true })

      subject.notify('notify', 'any title', 'any message', 'any image', { :display_message => true })
    end

    it 'does not call display message if the display_message flag is not set' do
      subject.stub :system => true
      subject.should_receive(:display_message).never

      subject.notify('notify', 'any title', 'any message', 'any image', { })
    end
  end

  describe '.display_message' do
    before do
      subject.stub :system => true
    end

    it 'sets the display-time' do
      subject.should_receive(:system).with('tmux set display-time 3000').once
      subject.display_message 'success', 'any title', 'any message', :timeout => 3
    end

    it 'sets the background color' do
      subject.stub :tmux_color => 'blue'
      subject.should_receive(:system).with('tmux set message-bg blue').once
      subject.display_message 'success', 'any title', 'any message'
    end

    it 'displays the message' do
      subject.should_receive(:system).with('tmux display-message \'any title - any message\'').once
      subject.display_message 'success', 'any title', 'any message'
    end

    it 'formats the message' do
      subject.should_receive(:system).with('tmux display-message \'(any title) -> any message - line two\'').once
      subject.display_message 'success', 'any title', "any message\nline two", :message_format => '(%s) -> %s'
    end

    it 'handles line-breaks' do
      subject.should_receive(:system).with('tmux display-message \'any title - any message xx line two\'').once
      subject.display_message 'success', 'any title', "any message\nline two", :line_separator => ' xx '
    end

  end
end
