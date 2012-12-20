require 'spec_helper'

describe Guard::Notifier::Tmux do

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
      subject.should_receive(:system).with "tmux set status-left-bg green"

      subject.notify('success', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to black on success when black is passed in as an option' do
      subject.should_receive(:system).with "tmux set status-left-bg black"

      subject.notify('success', 'any title', 'any message', 'any image', { :success => 'black' })
    end

    it 'should set the tmux status bar color to red on failure' do
      subject.should_receive(:system).with "tmux set status-left-bg red"

      subject.notify('failed', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to yellow on pending' do
      subject.should_receive(:system).with "tmux set status-left-bg yellow"

      subject.notify('pending', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to green on notify' do
      subject.should_receive(:system).with "tmux set status-left-bg green"

      subject.notify('notify', 'any title', 'any message', 'any image', { })
    end

    it 'should set the right tmux status bar color on success when the right status bar is passed in as an option' do
      subject.should_receive(:system).with "tmux set status-right-bg green"

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

  describe '.display_message' do
    before do
      subject.stub :system => true
    end

    it 'sets the display-time' do
      subject.should_receive(:system).with('tmux set display-time 3000')
      subject.display_message 'success', 'any title', 'any message', :timeout => 3
    end

    it 'displays the message' do
      subject.should_receive(:system).with('tmux display-message \'any title - any message\'').once
      subject.display_message 'success', 'any title', 'any message'
    end

    it 'handles line-breaks' do
      subject.should_receive(:system).with('tmux display-message \'any title - any message xx line two\'').once
      subject.display_message 'success', 'any title', "any message\nline two", :line_separator => ' xx '
    end

    context 'with success message type options' do
      it 'formats the message' do
        subject.should_receive(:system).with('tmux display-message \'[any title] => any message - line two\'').once
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
        subject.should_receive(:system).with('tmux display-message \'[any title] === any message - line two\'').once
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
        subject.should_receive(:system).with('tmux display-message \'[any title] <=> any message - line two\'').once
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

  describe '.save_tmux_state' do
    before do
      subject.stub(:`).and_return("option1 setting1\noption2 setting2\n")
    end

    it 'saves the current tmux options' do
      subject.should_receive(:`).with('tmux show')
      subject.save_tmux_state
      subject.get_tmux_option("option1").should eq "setting1"
      subject.get_tmux_option("option2").should eq "setting2"
    end

    it 'sets the ready_to_restore flag to true after state is saved' do
      subject.should_receive(:`).with('tmux show')
      subject.save_tmux_state
      subject.ready_to_restore.should be_true
    end

  end

  describe '.restore_tmux_state' do
    before do
      subject.stub(:`).and_return("option1 setting1\noption2 setting2\n")
      subject.stub :system => true
    end

    it 'restores the tmux options' do
      subject.should_receive(:`).with('tmux show')
      subject.save_tmux_state
      subject.should_receive(:system).with('tmux set quiet off')
      subject.should_receive(:system).with('tmux set option2 setting2')
      subject.should_receive(:system).with('tmux set -u status-left-bg')
      subject.should_receive(:system).with('tmux set option1 setting1')
      subject.should_receive(:system).with('tmux set -u status-right-bg')
      subject.should_receive(:system).with('tmux set -u status-right-fg')
      subject.should_receive(:system).with('tmux set -u status-left-fg')
      subject.should_receive(:system).with('tmux set -u message-fg')
      subject.should_receive(:system).with('tmux set -u message-bg')
      subject.restore_tmux_state
    end

  end
end
