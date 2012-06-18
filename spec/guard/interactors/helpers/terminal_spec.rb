require 'spec_helper'
require 'guard/interactors/helpers/terminal'

describe Guard::TerminalHelper do
  subject do
    Class.new(::Guard::Interactor) { include Guard::TerminalHelper }.new
  end

  describe '#start' do
    context 'when running on a system that has stty' do
      before { subject.should_receive(:stty_exists?).and_return(true) }

      it 'stores the terminal settings' do
        subject.should_receive(:store_terminal_settings)
        subject.start
      end
    end

    context 'when running on a system without stty' do
      before { subject.should_receive(:stty_exists?).and_return(false) }

      it 'does not store the terminal settings' do
        subject.should_not_receive(:store_terminal_settings)
        subject.start
      end
    end
  end

  describe '#stop' do
    before { subject.instance_variable_set(:@thread, Thread.current) }

    context 'when running on a system that has stty' do
      before { subject.should_receive(:stty_exists?).and_return(true) }

      it 'restores the terminal settings' do
        subject.should_receive(:restore_terminal_settings)
        subject.stop
      end
    end

    context 'when running on a system without stty' do
      before { subject.should_receive(:stty_exists?).and_return(false) }

      it 'does not store the terminal settings' do
        subject.should_not_receive(:restore_terminal_settings)
        subject.stop
      end
    end
  end
  
end