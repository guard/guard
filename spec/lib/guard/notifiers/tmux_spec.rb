require 'spec_helper'

describe Guard::Notifier::Tmux do
  let(:notifier) { described_class.new }

  before do
    allow(::Guard::Sheller).to receive(:new).and_call_original
  end

  describe '.available?' do
    it 'checks if the binary is available' do
      expect(described_class).to receive(:_tmux_environment_available?) { true }

      expect(described_class).to be_available
    end

    context 'when the TMUX environment variable is set' do
      before { ENV['TMUX'] = 'something' }

      it 'returns true' do
        expect(described_class).to be_available
      end
    end

    context 'when the TMUX environment variable is not set' do
      before { ENV['TMUX'] = nil }

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
    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(success: 'rainbow', silent: true) }

      it 'uses these options by default' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-left-bg rainbow').and_call_original

      notifier.notify('any message', type: :success)
      end

      it 'overwrites object options with passed options' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-left-bg black').and_call_original

      notifier.notify('any message', type: :success, success: 'black')
      end
    end

    it 'sets the tmux status bar color to green on success' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-left-bg green').and_call_original

      notifier.notify('any message', type: :success)
    end

    it 'sets the tmux status bar color to black on success when black is passed in as an option' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-left-bg black').and_call_original

      notifier.notify('any message', type: :success, success: 'black')
    end

    it 'sets the tmux status bar color to red on failure' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-left-bg red').and_call_original

      notifier.notify('any message', type: :failed)
    end

    it 'sets the tmux status bar color to yellow on pending' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-left-bg yellow').and_call_original

      notifier.notify('any message', type: :pending)
    end

    it 'sets the tmux status bar color to green on notify' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-left-bg green').and_call_original

      notifier.notify('any message', type: :notify)
    end

    it 'sets the right tmux status bar color on success when the right status bar is passed in as an option' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-right-bg green').and_call_original

      notifier.notify('any message', color_location: 'status-right-bg')
    end

    it 'does not change colors when the change_color flag is disabled' do
      expect(::Guard::Sheller).to_not receive(:new)

      notifier.notify('any message', change_color: false)
    end

    it 'calls display_message if the display_message flag is set' do
      expect(notifier).to receive(:display_message).with('notify', 'Guard', 'any message', display_message: true)

      notifier.notify('any message', type: :notify, display_message: true)
    end

    it 'does not call display_message if the display_message flag is not set' do
      expect(notifier).to receive(:display_message).never

      notifier.notify('any message')
    end

    it 'calls display_title if the display_title flag is set' do
      expect(notifier).to receive(:display_title).with('notify', 'Guard', 'any message', display_title: true)

      notifier.notify('any message', type: :notify, display_title: true)
    end

    it 'does not call display_title if the display_title flag is not set' do
      expect(notifier).to receive(:display_title).never

      notifier.notify('any message')
    end

    it 'sets the color on multiple tmux settings when color_location is passed with an array' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q status-left-bg green').and_call_original
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q pane-border-fg green').and_call_original

      notifier.notify('any message', color_location: %w[status-left-bg pane-border-fg])
    end
  end

  describe '#display_title' do
    context 'for tmux >= 1.7' do
      before do
        allow(notifier).to receive(:_tmux_version).and_return(1.7)
      end

      it 'displays the title' do
        expect(::Guard::Sheller).to receive(:new).with("tmux set-option -q set-titles-string 'any title - any message'").and_call_original

        notifier.display_title 'success', 'any title', 'any message'
      end

      it 'shows only the first line of the message' do
        expect(::Guard::Sheller).to receive(:new).with("tmux set-option -q set-titles-string 'any title - any message'").and_call_original

        notifier.display_title 'success', 'any title', "any message\nline two"
      end

      context 'with success message type options' do
        it 'formats the message' do
          expect(::Guard::Sheller).to receive(:new).with("tmux set-option -q set-titles-string '[any title] => any message'").and_call_original

          notifier.display_title 'success', 'any title', "any message\nline two", success_title_format: '[%s] => %s', default_title_format: '(%s) -> %s'
        end
      end

      context 'with pending message type options' do
        it 'formats the message' do
          expect(::Guard::Sheller).to receive(:new).with("tmux set-option -q set-titles-string '[any title] === any message'").and_call_original

          notifier.display_title 'pending', 'any title', "any message\nline two", pending_title_format: '[%s] === %s', default_title_format: '(%s) -> %s'
        end
      end

      context 'with failed message type options' do
        it 'formats the message' do
          expect(::Guard::Sheller).to receive(:new).with("tmux set-option -q set-titles-string '[any title] <=> any message'").and_call_original

          notifier.display_title 'failed', 'any title', "any message\nline two", failed_title_format: '[%s] <=> %s', default_title_format: '(%s) -> %s'
        end
      end
    end

    context 'for tmux <= 1.6' do
      before do
        expect(notifier).to receive(:_tmux_version).and_return(1.6)
      end

      it 'does not add the quiet flag' do
        expect(::Guard::Sheller).to receive(:new).with("tmux set-option set-titles-string 'any title - any message'").and_call_original

        notifier.display_title 'success', 'any title', 'any message'
      end
    end
  end

  describe '#display_message' do
    it 'sets the display-time' do
      expect(::Guard::Sheller).to receive(:new).with('tmux set -q display-time 3000').and_call_original

      notifier.display_message 'success', 'any title', 'any message', timeout: 3
    end

    it 'displays the message' do
      expect(::Guard::Sheller).to receive(:new).with("tmux display-message 'any title - any message'").and_call_original

      notifier.display_message 'success', 'any title', 'any message'
    end

    it 'handles line-breaks' do
      expect(::Guard::Sheller).to receive(:new).with("tmux display-message 'any title - any message xx line two'").and_call_original

      notifier.display_message 'success', 'any title', "any message\nline two", line_separator: ' xx '
    end

    context 'with success message type options' do
      it 'formats the message' do
        expect(::Guard::Sheller).to receive(:new).with("tmux display-message '[any title] => any message - line two'").and_call_original

        notifier.display_message 'success', 'any title', "any message\nline two", success_message_format: '[%s] => %s', default_message_format: '(%s) -> %s'
      end

      it 'sets the foreground color based on the type for success' do
        expect(::Guard::Sheller).to receive(:new).with('tmux set -q message-fg green').and_call_original

        notifier.display_message 'success', 'any title', 'any message', { success_message_color: 'green' }
      end

      it 'sets the background color' do
        expect(::Guard::Sheller).to receive(:new).with('tmux set -q message-bg blue').and_call_original

        notifier.display_message 'success', 'any title', 'any message', { success: :blue }
      end
    end

    context 'with pending message type options' do
      it 'formats the message' do
        expect(::Guard::Sheller).to receive(:new).with("tmux display-message '[any title] === any message - line two'").and_call_original

        notifier.display_message 'pending', 'any title', "any message\nline two", pending_message_format: '[%s] === %s', default_message_format: '(%s) -> %s'
      end

      it 'sets the foreground color' do
        expect(::Guard::Sheller).to receive(:new).with('tmux set -q message-fg blue').and_call_original

        notifier.display_message 'pending', 'any title', 'any message', pending_message_color: 'blue'
      end

      it 'sets the background color' do
        expect(::Guard::Sheller).to receive(:new).with('tmux set -q message-bg white').and_call_original

        notifier.display_message 'pending', 'any title', 'any message', pending: :white
      end
    end

    context 'with failed message type options' do
      it 'formats the message' do
        expect(::Guard::Sheller).to receive(:new).with("tmux display-message '[any title] <=> any message - line two'").and_call_original

        notifier.display_message 'failed', 'any title', "any message\nline two", failed_message_format: '[%s] <=> %s', default_message_format: '(%s) -> %s'
      end

      it 'sets the foreground color' do
        expect(::Guard::Sheller).to receive(:new).with('tmux set -q message-fg red').and_call_original

        notifier.display_message 'failed', 'any title', 'any message', failed_message_color: 'red'
      end

      it 'sets the background color' do
        expect(::Guard::Sheller).to receive(:new).with('tmux set -q message-bg black').and_call_original

        notifier.display_message 'failed', 'any title', 'any message', failed: :black
      end
    end
  end

  describe '#turn_on' do
    before do
      described_class.turn_off
      allow(described_class).to receive(:_options_for_client).and_return(option1: 'setting1', option2: 'setting2')
      allow(described_class).to receive(:_clients).and_return(['tty'])
    end

    context 'when off' do
      before do
        described_class.turn_off
      end

      it 'resets the options store' do
        expect(described_class).to receive(:_reset_options_store).and_call_original

        described_class.turn_on
      end

      it 'saves the current tmux options' do
        # unstubing
        allow(described_class).to receive(:_options_for_client).and_call_original

        expect(::Guard::Sheller).to receive(:new).with('tmux show -t tty').and_call_original

        described_class.turn_on
      end
    end

    context 'when on' do
      before do
        described_class.turn_on
      end

      it 'does not reset the options store' do
        expect(described_class).to_not receive(:_reset_options_store)

        described_class.turn_on
      end

      it 'does not save the current tmux options' do
        expect(::Guard::Sheller).to_not receive(:new)

        described_class.turn_on
      end
    end
  end

  describe '#turn_off' do
    before do
      described_class.turn_off
      allow(described_class).to receive(:_options_for_client).and_return(option1: 'setting1', option2: 'setting2')
      allow(described_class).to receive(:_clients).and_return(['tty'])
    end

    context 'when on' do
      before do
        described_class.turn_on
      end

      it 'restores the tmux options' do
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q -u status-left-bg').and_call_original
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q -u status-right-bg').and_call_original
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q -u status-right-fg').and_call_original
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q -u status-left-fg').and_call_original
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q -u message-fg').and_call_original
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q -u message-bg').and_call_original
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q -u display-time').and_call_original
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q option1 setting1').and_call_original
        expect(::Guard::Sheller).to receive(:new).with('tmux set -t tty -q option2 setting2').and_call_original

        described_class.turn_off
      end

      it 'resets the options store' do
        expect(described_class).to receive(:_reset_options_store)

        described_class.turn_off
      end
    end

    context 'when off' do
      before do
        described_class.turn_off
      end

      it 'does not restore the tmux options' do
        expect(::Guard::Sheller).to_not receive(:new).with('tmux set -q -u status-left-bg')
        expect(::Guard::Sheller).to_not receive(:new).with('tmux set -q -u status-right-bg')
        expect(::Guard::Sheller).to_not receive(:new).with('tmux set -q -u status-right-fg')
        expect(::Guard::Sheller).to_not receive(:new).with('tmux set -q -u status-left-fg')
        expect(::Guard::Sheller).to_not receive(:new).with('tmux set -q -u message-fg')
        expect(::Guard::Sheller).to_not receive(:new).with('tmux set -q -u message-bg')

        described_class.turn_off
      end

      it 'does not reset the options store' do
        expect(described_class).to_not receive(:_reset_options_store)

        described_class.turn_off
      end
    end
  end

end
