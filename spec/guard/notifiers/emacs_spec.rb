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
    it 'should set correct modeline color using emacsclient' do
      subject.should_receive(:system).with do |command|
        command.should include("emacsclient")
        command.should include("(set-face-background 'modeline \\\"ForestGreen\\\")")
      end

      subject.notify('success', 'any title', 'any message', 'any image', { })
    end
  end
end
