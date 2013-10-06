require 'spec_helper'

describe Guard::Notifier::Emacs do
  let(:notifier) { described_class.new }

  describe '.notify' do
    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(success: 'Green') }

      it 'uses these options by default' do
        notifier.should_receive(:_run_cmd).with do |*command|
          expect(command).to include("emacsclient")
          expect(command).to include(%{(set-face-attribute 'mode-line nil :background "Green" :foreground "White")})
        end

        notifier.notify('any message')
      end

      it 'overwrites object options with passed options' do
        notifier.should_receive(:_run_cmd).with do |*command|
          expect(command).to include("emacsclient")
          expect(command).to include(%{(set-face-attribute 'mode-line nil :background "LightGreen" :foreground "White")})
        end

        notifier.notify('any message', success: 'LightGreen')
      end
    end

    context 'when no color options are specified' do
      it 'should set modeline color to the default color using emacsclient' do
        notifier.should_receive(:_run_cmd).with do |*command|
          expect(command).to include("emacsclient")
          expect(command).to include(%{(set-face-attribute 'mode-line nil :background "ForestGreen" :foreground "White")})
        end

        notifier.notify('any message')
      end
    end

    context 'when a color option is specified for "success" notifications' do
      it 'should set modeline color to the specified color using emacsclient' do
        notifier.should_receive(:_run_cmd).with do |*command|
          expect(command).to include("emacsclient")
          expect(command).to include(%{(set-face-attribute 'mode-line nil :background "Orange" :foreground "White")})
        end

        notifier.notify('any message', success: 'Orange')
      end
    end

    context 'when a color option is specified for "pending" notifications' do
      it 'should set modeline color to the specified color using emacsclient' do
        notifier.should_receive(:_run_cmd).with do |*command|
          expect(command).to include("emacsclient")
          expect(command).to include(%{(set-face-attribute 'mode-line nil :background "Yellow" :foreground "White")})
        end

        notifier.notify('any message', type: :pending, pending: 'Yellow')
      end
    end
  end

end
