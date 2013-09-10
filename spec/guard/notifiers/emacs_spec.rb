require 'spec_helper'

describe Guard::Notifier::Emacs do
  let(:notifier) { described_class.new }

  describe '.notify' do
    context 'when no color options are specified' do
      it 'should set modeline color to the default color using emacsclient' do
        notifier.should_receive(:_run_cmd).with do |*command|
          command.should include("emacsclient")
          command.should include(%{(set-face-attribute 'mode-line nil :background "ForestGreen" :foreground "White")})
        end

        notifier.notify('any message')
      end
    end

    context 'when a color option is specified for "success" notifications' do
      it 'should set modeline color to the specified color using emacsclient' do
        notifier.should_receive(:_run_cmd).with do |*command|
          command.should include("emacsclient")
          command.should include(%{(set-face-attribute 'mode-line nil :background "Orange" :foreground "White")})
        end

        notifier.notify('any message', success: 'Orange')
      end
    end

    context 'when a color option is specified for "pending" notifications' do
      it 'should set modeline color to the specified color using emacsclient' do
        notifier.should_receive(:_run_cmd).with do |*command|
          command.should include("emacsclient")
          command.should include(%{(set-face-attribute 'mode-line nil :background "Yellow" :foreground "White")})
        end

        notifier.notify('any message', type: :pending, pending: 'Yellow')
      end
    end
  end

end
