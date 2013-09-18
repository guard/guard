require 'spec_helper'

describe Guard::Notifier::Tmux do
  let(:notifier) { described_class.new }

  describe '.available?' do
    context 'when the TMUX environment variable is set' do
      before :each do
        ENV['TMUX'] = 'something'
      end

      it 'returns true' do
        expect(described_class).to be_available
      end
    end

    context 'when the TMUX environment variable is not set' do
      before :each do
        ENV['TMUX'] = nil
      end

      context 'without the silent option' do
        it 'shows an error message when the TMUX environment variable is not set' do
          expect(::Guard::UI).to receive(:error).with 'The :tmux notifier runs only on when Guard is executed inside of a tmux session.'

          expect(described_class).not_to be_available
        end
      end

      context 'with the silent option' do
        it 'returns false' do
          expect(described_class).not_to be_available(silent: true)
        end
      end
    end
  end

  describe '#notify' do
    it 'should set the tmux status bar color to green on success' do
      expect(notifier).to receive(:system).with 'tmux set status-left-bg green'

      notifier.notify('any message', type: :success)
    end

    it 'should set the tmux status bar color to black on success when black is passed in as an option' do
      expect(notifier).to receive(:system).with "tmux set status-left-bg black"

      notifier.notify('any message', type: :success, success: 'black')
    end

    it 'should set the tmux status bar color to red on failure' do
      expect(notifier).to receive(:system).with 'tmux set status-left-bg red'

      notifier.notify('any message', type: :failed)
    end

    it 'should set the tmux status bar color to yellow on pending' do
      expect(notifier).to receive(:system).with 'tmux set status-left-bg yellow'

      notifier.notify('any message', type: :pending)
    end

    it 'should set the tmux status bar color to green on notify' do
      expect(notifier).to receive(:system).with 'tmux set status-left-bg green'

      notifier.notify('any message', type: :notify)
    end

    it 'should set the right tmux status bar color on success when the right status bar is passed in as an option' do
      expect(notifier).to receive(:system).with 'tmux set status-right-bg green'

      notifier.notify('any message', color_location: 'status-right-bg')
    end

    it 'calls display_message if the display_message flag is set' do
      notifier.stub system: true
      expect(notifier).to receive(:display_message).with('notify', 'Guard', 'any message', display_message: true)

      notifier.notify('any message', type: :notify, display_message: true)
    end

    it 'does not call display message if the display_message flag is not set' do
      notifier.stub system: true
      expect(notifier).to receive(:display_message).never

      notifier.notify('any message')
    end
  end

  describe '#display_message' do
    before do
      notifier.stub system: true
    end

    it 'sets the display-time' do
      expect(notifier).to receive(:system).with('tmux set display-time 3000')

      notifier.display_message 'success', 'any title', 'any message', timeout: 3
    end

    it 'displays the message' do
      expect(notifier).to receive(:system).with('tmux display-message \'any title - any message\'').once

      notifier.display_message 'success', 'any title', 'any message'
    end

    it 'handles line-breaks' do
      expect(notifier).to receive(:system).with('tmux display-message \'any title - any message xx line two\'').once

      notifier.display_message 'success', 'any title', "any message\nline two", line_separator: ' xx '
    end

    context 'with success message type options' do
      it 'formats the message' do
        expect(notifier).to receive(:system).with('tmux display-message \'[any title] => any message - line two\'').once

        notifier.display_message 'success', 'any title', "any message\nline two", success_message_format: '[%s] => %s', default_message_format: '(%s) -> %s'
      end

      it 'sets the foreground color based on the type for success' do
        expect(notifier).to receive(:system).with('tmux set message-fg green')

        notifier.display_message 'success', 'any title', 'any message', { success_message_color: 'green' }
      end

      it 'sets the background color' do
        expect(notifier).to receive(:system).with('tmux set message-bg blue')

        notifier.display_message 'success', 'any title', 'any message', { success: :blue }
      end
    end

    context 'with pending message type options' do
      it 'formats the message' do
        expect(notifier).to receive(:system).with('tmux display-message \'[any title] === any message - line two\'').once

        notifier.display_message 'pending', 'any title', "any message\nline two", pending_message_format: '[%s] === %s', default_message_format: '(%s) -> %s'
      end

      it 'sets the foreground color' do
        expect(notifier).to receive(:system).with('tmux set message-fg blue')

        notifier.display_message 'pending', 'any title', 'any message', pending_message_color: 'blue'
      end

      it 'sets the background color' do
        expect(notifier).to receive(:system).with('tmux set message-bg white')

        notifier.display_message 'pending', 'any title', 'any message', pending: :white
      end
    end

    context 'with failed message type options' do
      it 'formats the message' do
        expect(notifier).to receive(:system).with('tmux display-message \'[any title] <=> any message - line two\'').once

        notifier.display_message 'failed', 'any title', "any message\nline two", failed_message_format: '[%s] <=> %s', default_message_format: '(%s) -> %s'
      end

      it 'sets the foreground color' do
        expect(notifier).to receive(:system).with('tmux set message-fg red')
        notifier.display_message 'failed', 'any title', 'any message', failed_message_color: 'red'
      end

      it 'sets the background color' do
        expect(notifier).to receive(:system).with('tmux set message-bg black')
        notifier.display_message 'failed', 'any title', 'any message', failed: :black
      end
    end

  end

  describe '.turn_on' do
    before do
      notifier.stub(:`).and_return("option1 setting1\noption2 setting2\n")
      notifier.stub system: true
    end

    it 'quiets the tmux output' do
      expect(notifier).to receive(:system).with 'tmux set quiet on'

      notifier.turn_on
    end

    context 'when off' do
      before do
        notifier.turn_off
      end

      it 'resets the options store' do
        expect(notifier).to receive(:_reset_options_store)

        notifier.turn_on
      end

      it 'saves the current tmux options' do
        expect(notifier).to receive(:`).with('tmux show')

        notifier.turn_on
      end
    end

    context 'when on' do
      before do
        notifier.turn_on
      end

      it 'does not reset the options store' do
        expect(notifier).to_not receive(:_reset_options_store)

        notifier.turn_on
      end

      it 'does not save the current tmux options' do
        expect(notifier).to_not receive(:`).with('tmux show')

        notifier.turn_on
      end
    end
  end

  describe '.turn_off' do
    before do
      notifier.stub(:`).and_return("option1 setting1\noption2 setting2\n")
      notifier.stub system: true
    end

    context 'when on' do
      before do
        notifier.turn_on
      end

      it 'restores the tmux options' do
        expect(notifier).to receive(:system).with('tmux set option2 setting2')
        expect(notifier).to receive(:system).with('tmux set -u status-left-bg')
        expect(notifier).to receive(:system).with('tmux set option1 setting1')
        expect(notifier).to receive(:system).with('tmux set -u status-right-bg')
        expect(notifier).to receive(:system).with('tmux set -u status-right-fg')
        expect(notifier).to receive(:system).with('tmux set -u status-left-fg')
        expect(notifier).to receive(:system).with('tmux set -u message-fg')
        expect(notifier).to receive(:system).with('tmux set -u message-bg')

        notifier.turn_off
      end

      it 'resets the options store' do
        expect(notifier).to receive(:_reset_options_store)

        notifier.turn_off
      end

      it 'unquiets the tmux output' do
        expect(notifier).to receive(:system).with 'tmux set quiet off'

        notifier.turn_off
      end
    end

    context 'when off' do
      before do
        notifier.turn_off
      end

      it 'does not restore the tmux options' do
        expect(notifier).to_not receive(:system).with('tmux set -u status-left-bg')
        expect(notifier).to_not receive(:system).with('tmux set -u status-right-bg')
        expect(notifier).to_not receive(:system).with('tmux set -u status-right-fg')
        expect(notifier).to_not receive(:system).with('tmux set -u status-left-fg')
        expect(notifier).to_not receive(:system).with('tmux set -u message-fg')
        expect(notifier).to_not receive(:system).with('tmux set -u message-bg')

        notifier.turn_off
      end

      it 'does not reset the options store' do
        expect(notifier).to_not receive(:_reset_options_store)

        notifier.turn_off
      end

      it 'unquiets the tmux output' do
        expect(notifier).to receive(:system).with 'tmux set quiet off'

        notifier.turn_off
      end
    end
  end

end
