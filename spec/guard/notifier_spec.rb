require 'spec_helper'

describe Guard::Notifier do
  let(:gntp)  { { :name => :gntp, :options => {} } }
  let(:growl) { { :name => :growl, :options => {} } }
  let(:gntp_object) { double('GNTP').as_null_object }
  let(:growl_object) { double('Growl').as_null_object }

  describe '.turn_on' do
    context 'with configured notifications' do
      before do
        Guard::Notifier.notifiers = [gntp]
      end

      it 'shows the used notifications' do
        Guard::UI.should_receive(:info).with 'Guard is using GNTP to send notifications.'

        Guard::Notifier.turn_on
      end

      it 'enables the notifications' do
        Guard::Notifier.turn_on

        Guard::Notifier.should be_enabled
      end

      it 'turns on the defined notification module' do
        Guard::Notifier::GNTP.should_receive(:turn_on)

        Guard::Notifier.turn_on
      end
    end

    context 'without configured notifiers' do
      before do
        Guard::Notifier.clear_notifiers
      end

      context 'when notifications are globally enabled' do
        before do
          ::Guard.options = ::Guard::Options.new
          ::Guard.options.should_receive(:notify).and_return true
        end

        it 'tries to add each available notification silently' do
          Guard::Notifier.should_receive(:add_notifier).with(:gntp, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:growl, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:growl_notify, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:terminal_notifier, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:libnotify, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:notifysend, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:notifu, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:emacs, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:terminal_title, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:tmux, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:file, :silent => true).and_return false

          Guard::Notifier.turn_on
        end

        it 'adds only the first notification per group' do
          Guard::Notifier.should_receive(:add_notifier).with(:gntp, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:growl, :silent => true).and_return false
          Guard::Notifier.should_receive(:add_notifier).with(:growl_notify, :silent => true).and_return true
          Guard::Notifier.should_not_receive(:add_notifier).with(:terminal_notifier, :silent => true)
          Guard::Notifier.should_not_receive(:add_notifier).with(:libnotify, :silent => true)
          Guard::Notifier.should_not_receive(:add_notifier).with(:notifysend, :silent => true)
          Guard::Notifier.should_not_receive(:add_notifier).with(:notifu, :silent => true)
          Guard::Notifier.should_receive(:add_notifier).with(:emacs, :silent => true)
          Guard::Notifier.should_receive(:add_notifier).with(:terminal_title, :silent => true)
          Guard::Notifier.should_receive(:add_notifier).with(:tmux, :silent => true)
          Guard::Notifier.should_receive(:add_notifier).with(:file, :silent => true)

          Guard::Notifier.turn_on
        end

        it 'does enable the notifications when a library is available' do
          Guard::Notifier.stub(:add_notifier) do
            Guard::Notifier.notifiers = [gntp]
            true
          end
          Guard::Notifier.turn_on
          Guard::Notifier.should be_enabled
        end

        it 'does turn on the notification module for libraries that are available' do
          Guard::Notifier.stub(:add_notifier) do
            Guard::Notifier.notifiers = [{ :name => :tmux, :options => {} }]
            true
          end.any_number_of_times
          Guard::Notifier::Tmux.should_receive(:turn_on)

          Guard::Notifier.turn_on
        end

        it 'does not enable the notifications when no library is available' do
          Guard::Notifier.stub(:add_notifier).any_number_of_times.and_return false
          Guard::Notifier.turn_on
          Guard::Notifier.should_not be_enabled
        end
      end

      context 'when notifications are globally disabled' do
        before do
          ::Guard.options = ::Guard::Options.new
          ::Guard.options.should_receive(:notify).and_return false
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
      Guard::Notifier.turn_off
      ENV['GUARD_NOTIFY'].should eq 'false'
    end

    context 'when turned on with available notifications' do
      before do
        Guard::Notifier.notifiers = [{ :name => :tmux, :options => {} }]
      end

      it 'turns off each notifier' do
        Guard::Notifier::Tmux.should_receive(:turn_off)

        Guard::Notifier.turn_off
      end
    end
  end

  describe 'toggle_notification' do
    before { ::Guard::UI.stub(:info) }

    it 'disables the notifications when enabled' do
      ENV['GUARD_NOTIFY'] = 'true'
      ::Guard::Notifier.should_receive(:turn_off)
      subject.toggle
    end

    it 'enables the notifications when disabled' do
      ENV['GUARD_NOTIFY'] = 'false'
      ::Guard::Notifier.should_receive(:turn_on)
      subject.toggle
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

  describe '.add_notifier' do
    before do
      Guard::Notifier.clear_notifiers
    end

    context 'for an unknown notification library' do
      it 'does not add the library' do
        Guard::Notifier.add_notifier(:unknown)

        Guard::Notifier.notifiers.should be_empty
      end
    end

    context 'for a notification library with the name :off' do
      it 'disables the notifier' do
        ENV['GUARD_NOTIFY'] = 'true'
        Guard::Notifier.should be_enabled
        Guard::Notifier.add_notifier(:off)

        Guard::Notifier.should_not be_enabled
      end
    end

    context 'for a supported notification library' do
      context 'that is available' do
        it 'adds the notifier to the notifications' do
          Guard::Notifier::GNTP.should_receive(:available?).with(:param => 1).and_return(true)

          Guard::Notifier.add_notifier(:gntp, :param => 1)

          Guard::Notifier.notifiers.should eq [{ :name => :gntp, :options => { :param => 1 } }]
        end
      end

      context 'that is not available' do
        it 'does not add the notifier to the notifications' do
          Guard::Notifier::GNTP.should_receive(:available?).with(:param => 1).and_return(false)
          Guard::Notifier.add_notifier(:gntp, :param => 1)

          Guard::Notifier.notifiers.should be_empty
        end
      end
    end
  end

  describe '.notify' do
    before { Guard::Notifier.notifiers = [gntp, growl] }

    context 'when notifications are enabled' do
      before do
        Guard::Notifier.stub(:enabled?).and_return true

        Guard::Notifier::GNTP.should_receive(:new).with({}).and_return(gntp_object)
        Guard::Notifier::Growl.should_receive(:new).with({}).and_return(growl_object)
      end

      it 'sends the notification to multiple notifier' do
        Guard::Notifier.notifiers = [gntp, growl]
        gntp_object.should_receive(:notify).with('Hi to everyone', :foo => 'bar')
        growl_object.should_receive(:notify).with('Hi to everyone', :foo => 'bar')

        ::Guard::Notifier.notify('Hi to everyone', :foo => 'bar')
      end
    end

    context 'when notifications are disabled' do
      before do
        Guard::Notifier.stub(:enabled?).and_return false
      end

      it 'does not send any notifications to a notifier' do
        gntp.should_not_receive(:notify)
        growl.should_not_receive(:notify)

        ::Guard::Notifier.notify('Hi to everyone')
      end
    end
  end

end
