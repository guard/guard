require 'spec_helper'

include Guard

describe Guard::Notifier::Emacs do
  let(:notifier) { described_class.new }

  describe '.available?' do
    it 'checks if the client is available' do
      expect(described_class).to receive(:_emacs_client_available?) { true }

      expect(described_class).to be_available
    end
  end

  describe '.notify' do
    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(success: 'Green', silent: true) }

      it 'uses these options by default' do
        expect(Sheller).to receive(:run) do |command, *arguments|
          expect(command).to include('emacsclient')
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"Green\" :foreground \"White\")"
          )
        end

        notifier.notify('any message')
      end

      it 'overwrites object options with passed options' do
        expect(Sheller).to receive(:run) do |command, *arguments|
          expect(command).to include('emacsclient')
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"LightGreen\" :foreground \"White\")"
          )
        end

        notifier.notify('any message', success: 'LightGreen')
      end
    end

    context 'when no color options are specified' do
      it 'should set modeline color to the default color using emacsclient' do
        expect(Sheller).to receive(:run) do |command, *arguments|
          expect(command).to include('emacsclient')
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"ForestGreen\" :foreground \"White\")"
          )
        end

        notifier.notify('any message')
      end
    end

    context 'when a color option is specified for "success" notifications' do
      it 'should set modeline color to the specified color using emacsclient' do
        expect(Sheller).to receive(:run) do |command, *arguments|
          expect(command).to include('emacsclient')
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"Orange\" :foreground \"White\")"
          )
        end

        notifier.notify('any message', success: 'Orange')
      end
    end

    context 'when a color option is specified for "pending" notifications' do
      it 'should set modeline color to the specified color using emacsclient' do
        expect(Sheller).to receive(:run) do |command, *arguments|
          expect(command).to include('emacsclient')
          expect(arguments).to include(
            "(set-face-attribute 'mode-line nil"\
            " :background \"Yellow\" :foreground \"White\")"
          )
        end

        notifier.notify('any message', type: :pending, pending: 'Yellow')
      end
    end
  end
end
