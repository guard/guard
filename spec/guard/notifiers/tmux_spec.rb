require 'spec_helper'

describe Guard::Notifier::Tmux do
  before(:all) { Object.send(:remove_const, :Tmux) if defined?(::Tmux) }

  before do
    class ::Tmux
      def self.show(options) end
    end
  end

  after { Object.send(:remove_const, :Tmux) if defined?(::Tmux) }

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
          ::Guard::UI.should_receive(:error).with "The :tmux notifier runs only on when guard is executed inside of a tmux session."
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
      subject.should_receive(:system).with "tmux set -g status-left-bg green"

      subject.notify('success', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to black on success when black is passed in as an option' do
      subject.should_receive(:system).with "tmux set -g status-left-bg black"

      subject.notify('success', 'any title', 'any message', 'any image', { :success => 'black' })
    end

    it 'should set the tmux status bar color to red on failure' do
      subject.should_receive(:system).with "tmux set -g status-left-bg red"

      subject.notify('failed', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to green on pending' do
      subject.should_receive(:system).with "tmux set -g status-left-bg green"

      subject.notify('pending', 'any title', 'any message', 'any image', { })
    end

    it 'should set the tmux status bar color to green on notify' do
      subject.should_receive(:system).with "tmux set -g status-left-bg green"

      subject.notify('notify', 'any title', 'any message', 'any image', { })
    end
  end
end
