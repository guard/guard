require 'spec_helper'

describe Guard::Notifier::Emacs do

  describe '.notify' do
    context 'when no color options are specified' do
      it 'should set modeline color to the default color using emacsclient' do
        subject.should_receive(:system).with do |command|
          command.should include("emacsclient")
          command.should include("(set-face-attribute 'mode-line nil :background \\\"ForestGreen\\\" :foreground \\\"White\\\")")
        end

        subject.notify('success', 'any title', 'any message', 'any image', { })
      end
    end

    context 'when a color option is specified for "success" notifications' do
      let(:options) { {:success => 'Orange'} }

      it 'should set modeline color to the specified color using emacsclient' do
        subject.should_receive(:system).with do |command|
          command.should include("emacsclient")
          command.should include("(set-face-attribute 'mode-line nil :background \\\"Orange\\\" :foreground \\\"White\\\")")
        end

        subject.notify('success', 'any title', 'any message', 'any image', options)
      end
    end

    context 'when a color option is specified for "pending" notifications' do
      let(:options) { {:pending => 'Yellow'} }

      it 'should set modeline color to the specified color using emacsclient' do
        subject.should_receive(:system).with do |command|
          command.should include("emacsclient")
          command.should include("(set-face-attribute 'mode-line nil :background \\\"Yellow\\\" :foreground \\\"White\\\")")
        end

        subject.notify('pending', 'any title', 'any message', 'any image', options)
      end
    end
  end
end
