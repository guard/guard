require 'spec_helper'

describe Guard::Notifier::GNTP do
  before(:all) { Object.send(:remove_const, :GNTP) if defined?(::GNTP) }

  before do
    subject.stub(:require)

    class ::GNTP
      def self.notify(options) end
    end
  end

  after { Object.send(:remove_const, :GNTP) if defined?(::GNTP) }

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :gntp notifier runs only on Mac OS X, Linux, FreeBSD, OpenBSD, Solaris and Windows.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'os2'
        subject.available?
      end

      it 'shows an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::Guard::UI.should_receive(:error).with "Please add \"gem 'ruby_gntp'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('ruby_gntp').and_raise LoadError
        subject.available?
      end
    end

    context 'with the silent option' do
      it 'does not show an error message when not available on the host OS' do
        ::Guard::UI.should_not_receive(:error).with 'The :gntp notifier runs only on Mac OS X, Linux, FreeBSD, OpenBSD, Solaris and Windows.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'os2'
        subject.available?(true)
      end

      it 'does not show an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::Guard::UI.should_not_receive(:error).with "Please add \"gem 'ruby_gntp'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('ruby_gntp').and_raise LoadError
        subject.available?(true)
      end
    end
  end

  describe '.nofify' do
    let(:gntp) { mock('GNTP').as_null_object }

    before do
      ::GNTP.stub(:new).and_return gntp
    end

    it 'requires the library again' do
      subject.should_receive(:require).with('ruby_gntp').and_return true
      subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
    end

    it 'opens GNTP as Guard application' do
      ::GNTP.should_receive(:new).with('Guard', 'localhost', '', 23053)
      subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
    end

    context 'when not registered' do
      before { Guard::Notifier::GNTP.instance_variable_set :@registered, false }

      it 'registers the Guard notification types' do
        gntp.should_receive(:register)
        subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
      end
    end

    context 'when already registered' do
      before { Guard::Notifier::GNTP.instance_variable_set :@registered, true }

      it 'registers the Guard notification types' do
        gntp.should_not_receive(:register)
        subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
      end
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        gntp.should_receive(:notify).with({
            :sticky => false,
            :name   => 'success',
            :title  => 'Welcome',
            :text   => 'Welcome to Guard',
            :icon   => 'file:///tmp/welcome.png'
        })
        subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        gntp.should_receive(:notify).with({
            :sticky => true,
            :name   => 'pending',
            :title  => 'Waiting',
            :text   => 'Waiting for something',
            :icon   => 'file:///tmp/wait.png'
        })
        subject.notify('pending', 'Waiting', 'Waiting for something', '/tmp/wait.png', {
            :sticky => true,
        })
      end

      it 'cannot override the core options' do
        gntp.should_receive(:notify).with({
            :sticky => false,
            :name   => 'failed',
            :title  => 'Failed',
            :text   => 'Something failed',
            :icon   => 'file:///tmp/fail.png'
        })
        subject.notify('failed', 'Failed', 'Something failed', '/tmp/fail.png', {
            :name  => 'custom',
            :title => 'Duplicate title',
            :text  => 'Duplicate text',
            :icon  => 'Duplicate icon'
        })
      end
    end
  end

end
