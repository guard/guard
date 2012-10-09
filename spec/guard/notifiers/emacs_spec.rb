require 'spec_helper'

describe Guard::Notifier::Emacs do
  before(:all) { Object.send(:remove_const, :Emacs) if defined?(::Emacs) }

  before do
    class ::Emacs
      def self.show(options) end
    end
  end

  after { Object.send(:remove_const, :Emacs) if defined?(::Emacs) }

  describe '.notify' do
    context 'when no color options are specified' do
      it 'should set modeline color to the default color using emacsclient' do
        subject.should_receive(:system).with do |command|
          command.should include("emacsclient")
          command.should include("(set-face-background 'modeline \\\"ForestGreen\\\")")
        end

        subject.notify('success', 'any title', 'any message', 'any image', { })
      end
    end

    context 'when a color option is specified for "success" notifications' do
      let(:options) { {:success => 'Orange'} }

      it 'should set modeline color to the specified color using emacsclient' do
        subject.should_receive(:system).with do |command|
          command.should include("emacsclient")
          command.should include("(set-face-background 'modeline \\\"Orange\\\")")
        end

        subject.notify('success', 'any title', 'any message', 'any image', options)
      end
    end
  end
end
