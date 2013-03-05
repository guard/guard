require 'spec_helper'

describe Guard::Notifier::Tmux do

  describe '.available?' do
    context 'when the TMUX environment variable is set' do
      before :each do
        ENV['TMUX'] = 'something'
      end

      it 'should return true' do
        subject.available?.should be_true
      end
    end

    context 'when the TMUX environment variable is not set' do
      before :each do
        ENV['TMUX'] = nil
      end

      context 'without the silent option' do
        it 'shows an error message when the TMUX environment variable is not set' do
          ::Guard::UI.should_receive(:error).with 'The :tmux notifier runs only on when Guard is executed inside of a tmux session.'
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
      subject.should_receive(:system).with 'tmux set status-left-bg green'

      subject.notify('success', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to black on success when black is passed in as an option' do
      subject.should_receive(:system).with "tmux set status-left-bg black"

      subject.notify('success', 'any title', 'any message', 'any image', { :success => 'black' })
    end

    it 'should set the tmux status bar color to red on failure' do
      subject.should_receive(:system).with 'tmux set status-left-bg red'

      subject.notify('failed', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to yellow on pending' do
      subject.should_receive(:system).with 'tmux set status-left-bg yellow'

      subject.notify('pending', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to green on notify' do
      subject.should_receive(:system).with 'tmux set status-left-bg green'

      subject.notify('notify', 'any title', 'any message', 'any image', { })
    end

    it 'should set the right tmux status bar color on success when the right status bar is passed in as an option' do
      subject.should_receive(:system).with 'tmux set status-right-bg green'

      subject.notify('success', 'any title', 'any message', 'any image', { :color_location => 'status-right-bg' })
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

  describe '.display_and_restore' do
    it 'displays the provided message and restores tmux options afterwards' do
      subject.stub :system => true
      subject.should_receive(:system).with('tmux display-message \'hello world\'').once
      subject.should_receive(:restore_options)
      subject.send :display_and_restore, 'hello world', 0.1
      sleep 0.2
    end
  end

  describe '.display_message' do
    before do
      subject.stub :system => true, :display_and_restore => true
    end

    it 'sets the display-time' do
      subject.should_receive(:system).with('tmux set display-time 3000')
      subject.display_message 'success', 'any title', 'any message', :timeout => 3
    end

    it 'displays the message' do
      subject.should_receive(:display_and_restore).with('any title - any message', 5).once
      subject.display_message 'success', 'any title', 'any message'
    end

    it 'handles line-breaks' do
      subject.should_receive(:display_and_restore).with('any title - any message xx line two', 5).once
      subject.display_message 'success', 'any title', "any message\nline two", :line_separator => ' xx '
    end

    context 'with success message type options' do
      it 'formats the message' do
        subject.should_receive(:display_and_restore).with('[any title] => any message - line two', 5).once
        subject.display_message 'success', 'any title', "any message\nline two", :success_message_format => '[%s] => %s', :default_message_format => '(%s) -> %s'
      end

      it 'sets the foreground color based on the type for success' do
        subject.should_receive(:system).with('tmux set message-fg green')
        subject.display_message 'success', 'any title', 'any message', { :success_message_color => 'green' }
      end

      it 'sets the background color' do
        subject.should_receive(:system).with('tmux set message-bg blue')
        subject.display_message 'success', 'any title', 'any message', { :success => :blue }
      end
    end

    context 'with pending message type options' do
      it 'formats the message' do
        subject.should_receive(:display_and_restore).with('[any title] === any message - line two', 5).once
        subject.display_message 'pending', 'any title', "any message\nline two", :pending_message_format => '[%s] === %s', :default_message_format => '(%s) -> %s'
      end

      it 'sets the foreground color' do
        subject.should_receive(:system).with('tmux set message-fg blue')
        subject.display_message 'pending', 'any title', 'any message', { :pending_message_color => 'blue' }
      end

      it 'sets the background color' do
        subject.should_receive(:system).with('tmux set message-bg white')
        subject.display_message 'pending', 'any title', 'any message', { :pending => :white }
      end
    end

    context 'with failed message type options' do
      it 'formats the message' do
        subject.should_receive(:display_and_restore).with('[any title] <=> any message - line two', 5).once
        subject.display_message 'failed', 'any title', "any message\nline two", :failed_message_format => '[%s] <=> %s', :default_message_format => '(%s) -> %s'
      end

      it 'sets the foreground color' do
        subject.should_receive(:system).with('tmux set message-fg red')
        subject.display_message 'failed', 'any title', 'any message', { :failed_message_color => 'red' }
      end

      it 'sets the background color' do
        subject.should_receive(:system).with('tmux set message-bg black')
        subject.display_message 'failed', 'any title', 'any message', { :failed => :black }
      end
    end

  end

  describe '.turn_on' do
    before do
      subject.stub(:`).and_return("option1 setting1\noption2 setting2\n")
      subject.stub :system => true
    end

    it 'quiets the tmux output' do
      subject.should_receive(:system).with 'tmux set quiet on'
      subject.turn_on
    end

    context 'when off' do
      before do
        subject.turn_off
      end

      it 'resets the options store' do
        subject.should_receive(:reset_options_store)
        subject.turn_on
      end

      it 'saves the current tmux options' do
        subject.should_receive(:`).with('tmux show-options -g; tmux show-options')
        subject.turn_on
      end
    end

    context 'when on' do
      before do
        subject.turn_on
      end

      it 'does not reset the options store' do
        subject.should_not_receive(:reset_options_store)
        subject.turn_on
      end

      it 'does not save the current tmux options' do
        subject.should_not_receive(:`).with('tmux show')
        subject.turn_on
      end
    end
  end

  describe '.turn_off' do
    before do
      subject.stub(:`).and_return("option1 setting1\ndisplay-time 10\n")
      subject.stub :system => true
    end

    context 'when on' do
      before do
        subject.turn_on
      end

      it 'restores the tmux options' do
        subject.should_receive(:system).with('tmux set display-time 10')
        subject.should_receive(:system).with('tmux set -u status-left-bg')
        subject.should_receive(:system).with('tmux set -u status-right-bg')
        subject.should_receive(:system).with('tmux set -u status-right-fg')
        subject.should_receive(:system).with('tmux set -u status-left-fg')
        subject.should_receive(:system).with('tmux set -u message-fg')
        subject.should_receive(:system).with('tmux set -u message-bg')
        subject.turn_off
      end

      it 'resets the options store' do
        subject.should_receive(:reset_options_store)
        subject.turn_off
      end

      it 'unquiets the tmux output' do
        subject.should_receive(:system).with 'tmux set quiet off'
        subject.turn_off
      end
    end

    context 'when off' do
      before do
        subject.turn_off
      end

      it 'does not restore the tmux options' do
        subject.should_not_receive(:system).with('tmux set -u status-left-bg')
        subject.should_not_receive(:system).with('tmux set -u status-right-bg')
        subject.should_not_receive(:system).with('tmux set -u status-right-fg')
        subject.should_not_receive(:system).with('tmux set -u status-left-fg')
        subject.should_not_receive(:system).with('tmux set -u message-fg')
        subject.should_not_receive(:system).with('tmux set -u message-bg')
        subject.turn_off
      end

      it 'does not reset the options store' do
        subject.should_not_receive(:reset_options_store)
        subject.turn_off
      end

      it 'unquiets the tmux output' do
        subject.should_receive(:system).with 'tmux set quiet off'
        subject.turn_off
      end
    end
  end
end
