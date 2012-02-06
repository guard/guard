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
end
