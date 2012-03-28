require 'spec_helper'

describe Guard::Notifier::Libnotify do
  before(:all) { Object.send(:remove_const, :Libnotify) if defined?(::Libnotify) }

  before do
    subject.stub(:require)

    class ::Libnotify
      def self.show(options) end
    end
  end

  after { Object.send(:remove_const, :Libnotify) if defined?(::Libnotify) }

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :libnotify notifier runs only on Linux, FreeBSD, OpenBSD and Solaris.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        subject.available?
      end

      it 'shows an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'linux'
        ::Guard::UI.should_receive(:error).with "Please add \"gem 'libnotify'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('libnotify').and_raise LoadError
        subject.available?
      end
    end

    context 'with the silent option' do
      it 'does not show an error message when not available on the host OS' do
        ::Guard::UI.should_not_receive(:error).with 'The :libnotify notifier runs only on Linux, FreeBSD, OpenBSD and Solaris.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        subject.available?(true)
      end

      it 'does not show an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'linux'
        ::Guard::UI.should_not_receive(:error).with "Please add \"gem 'libnotify'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('libnotify').and_raise LoadError
        subject.available?(true)
      end
    end
  end

  describe '.notify' do
    it 'requires the library again' do
      subject.should_receive(:require).with('libnotify').and_return true
      subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        ::Libnotify.should_receive(:show).with({
            :transient => false,
            :append    => true,
            :timeout   => 3,
            :urgency   => :low,
            :summary   => 'Welcome',
            :body      => 'Welcome to Guard',
            :icon_path => '/tmp/welcome.png'
        })
        subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        ::Libnotify.should_receive(:show).with({
            :transient => true,
            :append    => false,
            :timeout   => 5,
            :urgency   => :critical,
            :summary   => 'Waiting',
            :body      => 'Waiting for something',
            :icon_path => '/tmp/wait.png'
        })
        subject.notify('pending', 'Waiting', 'Waiting for something', '/tmp/wait.png', {
            :transient => true,
            :append    => false,
            :timeout   => 5,
            :urgency   => :critical
        })
      end

      it 'cannot override the core options' do
        ::Libnotify.should_receive(:show).with({
            :transient => false,
            :append    => true,
            :timeout   => 3,
            :urgency   => :normal,
            :summary   => 'Failed',
            :body      => 'Something failed',
            :icon_path => '/tmp/fail.png'
        })
        subject.notify('failed', 'Failed', 'Something failed', '/tmp/fail.png', {
            :summary   => 'Duplicate title',
            :body      => 'Duplicate body',
            :icon_path => 'Duplicate icon'
        })
      end
    end
  end

end
