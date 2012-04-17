require 'spec_helper'

describe Guard::Notifier do

  describe '.turn_on' do
    context 'with configured notifications' do
      before do
        Guard::Notifier.notifications = [{ :name => :gntp, :options => { } }]
      end

      it 'shows the used notifications' do
        Guard::UI.should_receive(:info).with 'Guard uses GNTP to send notifications.'
        Guard::Notifier.turn_on
      end

      it 'enables the notifications' do
        Guard::Notifier.turn_on
        Guard::Notifier.should be_enabled
      end
    end

    context 'without configured notifications' do
      before do
        Guard::Notifier.notifications = []
      end

      context 'when notifications are globally enabled' do
        before do
          ::Guard.options = { }
          ::Guard.options.should_receive(:[]).with(:notify).and_return true
        end

        it 'tries to add each available notification silently' do
          Guard::Notifier.should_receive(:add_notification).with(:growl_notify, { }, true).and_return false
          Guard::Notifier.should_receive(:add_notification).with(:gntp, { }, true).and_return false
          Guard::Notifier.should_receive(:add_notification).with(:growl, { }, true).and_return false
          Guard::Notifier.should_receive(:add_notification).with(:libnotify, { }, true).and_return false
          Guard::Notifier.should_receive(:add_notification).with(:notifysend, { }, true).and_return false
          Guard::Notifier.should_receive(:add_notification).with(:notifu, { }, true).and_return false
          Guard::Notifier.turn_on
        end

        it 'does enable the notifications when a library is available' do
          Guard::Notifier.should_receive(:add_notification) do
            Guard::Notifier.notifications = [{ :name => :gntp, :options => { } }]
            true
          end
          Guard::Notifier.turn_on
          Guard::Notifier.should be_enabled
        end

        it 'does not enable the notifications when no library is available' do
          Guard::Notifier.should_receive(:add_notification).any_number_of_times.and_return false
          Guard::Notifier.turn_on
          Guard::Notifier.should_not be_enabled
        end
      end

      context 'when notifications are globally disabled' do
        before do
          ::Guard.options = { }
          ::Guard.options.should_receive(:[]).with(:notify).and_return false
        end

        it 'does not try to add each available notification silently' do
          Guard::Notifier.should_not_receive(:auto_detect_notification)
          Guard::Notifier.turn_on
          Guard::Notifier.should_not be_enabled
        end
      end
    end
  end

  describe '.turn_off' do
    before { ENV['GUARD_NOTIFY'] = 'true' }

    it 'disables the notifications' do
      subject.turn_off
      ENV['GUARD_NOTIFY'].should == 'false'
    end
  end

  describe '.enabled?' do
    context 'when enabled' do
      before { ENV['GUARD_NOTIFY'] = 'true' }

      it { should be_enabled }
    end

    context 'when disabled' do
      before { ENV['GUARD_NOTIFY'] = 'false' }

      it { should_not be_enabled }
    end
  end

  describe '.add_notification' do
    before do
      Guard::Notifier.notifications = []
    end

    context 'for an unknown notification library' do
      it 'does not add the library' do
        Guard::Notifier.add_notification(:unknown)
        Guard::Notifier.notifications.should be_empty
      end
    end

    context 'for an notification library with the name :off' do
      it 'disables the notifier' do
        ENV['GUARD_NOTIFY'] = 'true'
        Guard::Notifier.should be_enabled
        Guard::Notifier.add_notification(:off)
        Guard::Notifier.should_not be_enabled
      end
    end

    context 'for a supported notification library' do
      context 'that is available' do
        it 'adds the notifier to the notifications' do
          Guard::Notifier::GNTP.should_receive(:available?).and_return true
          Guard::Notifier.add_notification(:gntp, { :param => 1 })
          Guard::Notifier.notifications.should include({ :name => :gntp, :options => { :param => 1 } })
        end
      end

      context 'that is not available' do
        it 'does not add the notifier to the notifications' do
          Guard::Notifier::GNTP.should_receive(:available?).and_return false
          Guard::Notifier.add_notification(:gntp, { :param => 1 })
          Guard::Notifier.notifications.should_not include({ :name => :gntp, :options => { :param => 1 } })
        end
      end
    end
  end

  describe '.notify' do
    context 'when notifications are enabled' do
      before do
        Guard::Notifier.notifications = [{ :name => :gntp, :options => { } }]
        Guard::Notifier.stub(:enabled?).and_return true
      end

      it 'uses the :success image when no image is defined' do
        Guard::Notifier::GNTP.should_receive(:notify).with('success', 'Hi', 'Hi to everyone', /success.png/, { })
        ::Guard::Notifier.notify('Hi to everyone', :title => 'Hi')
      end

      it 'uses "Guard" as title when no title is defined' do
        Guard::Notifier::GNTP.should_receive(:notify).with('success', 'Guard', 'Hi to everyone', /success.png/, { })
        ::Guard::Notifier.notify('Hi to everyone')
      end

      it 'sets the "failed" type for a :failed image' do
        Guard::Notifier::GNTP.should_receive(:notify).with('failed', 'Guard', 'Hi to everyone', /failed.png/, { })
        ::Guard::Notifier.notify('Hi to everyone', :image => :failed)
      end

      it 'sets the "pending" type for a :pending image' do
        Guard::Notifier::GNTP.should_receive(:notify).with('pending', 'Guard', 'Hi to everyone', /pending.png/, { })
        ::Guard::Notifier.notify('Hi to everyone', :image => :pending)
      end

      it 'sets the "success" type for a :success image' do
        Guard::Notifier::GNTP.should_receive(:notify).with('success', 'Guard', 'Hi to everyone', /success.png/, { })
        ::Guard::Notifier.notify('Hi to everyone', :image => :success)
      end

      it 'sets the "notify" type for a custom image' do
        Guard::Notifier::GNTP.should_receive(:notify).with('notify', 'Guard', 'Hi to everyone', '/path/to/image.png', { })
        ::Guard::Notifier.notify('Hi to everyone', :image => '/path/to/image.png')
      end

      it 'passes custom options to the notifier' do
        Guard::Notifier::GNTP.should_receive(:notify).with('success', 'Guard', 'Hi to everyone', /success.png/, { :param => 'test' })
        ::Guard::Notifier.notify('Hi to everyone', :param => 'test')
      end

      it 'sends the notification to multiple notifier' do
        Guard::Notifier.notifications = [{ :name => :gntp, :options => { } }, { :name => :growl, :options => { } }]
        Guard::Notifier::GNTP.should_receive(:notify)
        Guard::Notifier::Growl.should_receive(:notify)
        ::Guard::Notifier.notify('Hi to everyone')
      end
    end

    context 'when notifications are disabled' do
      before do
        Guard::Notifier.notifications = [{ :name => :gntp, :options => { } }, { :name => :growl, :options => { } }]
        Guard::Notifier.stub(:enabled?).and_return false
      end

      it 'does not send any notifications to a notifier' do
        Guard::Notifier::GNTP.should_not_receive(:notify)
        Guard::Notifier::Growl.should_not_receive(:notify)
        ::Guard::Notifier.notify('Hi to everyone')
      end
    end
  end

end
