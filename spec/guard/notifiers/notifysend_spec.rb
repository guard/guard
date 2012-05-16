require 'spec_helper'

describe Guard::Notifier::NotifySend do
  before(:all) { Object.send(:remove_const, :NotifySend) if defined?(::NotifySend) }

  before do
    class ::NotifySend
      def self.show(options) end
    end
  end

  after { Object.send(:remove_const, :NotifySend) if defined?(::NotifySend) }

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :notifysend notifier runs only on Linux, FreeBSD, OpenBSD and Solaris with the libnotify-bin package installed.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        subject.available?
      end
    end

    context 'with the silent option' do
      it 'does not show an error message when not available on the host OS' do
        ::Guard::UI.should_not_receive(:error).with 'The :notifysend notifier runs only on Linux, FreeBSD, OpenBSD and Solaris with the libnotify-bin package installed.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        subject.available?(true)
      end
    end
  end

  describe '.notify' do
    context 'without additional options' do
      it 'shows the notification with the default options' do
        subject.should_receive(:system).with do |command|
          command.should include("notify-send 'Welcome' 'Welcome to Guard'")
          command.should include("-i '/tmp/welcome.png'")
          command.should include("-u 'low'")
          command.should include("-t '3000'")
          command.should include("-h 'int:transient:1'")
        end
        subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        subject.should_receive(:system).with do |command|
          command.should include("notify-send 'Waiting' 'Waiting for something'")
          command.should include("-i '/tmp/wait.png'")
          command.should include("-u 'critical'")
          command.should include("-t '5'")
        end
        subject.notify('pending', 'Waiting', 'Waiting for something', '/tmp/wait.png', {
            :t => 5,
            :u => :critical
        })
      end
    end
  end
end
