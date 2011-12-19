require 'spec_helper'

describe Guard::Notifier::Notifu do
  before(:all) { Object.send(:remove_const, :Notifu) if defined?(::Notifu) }

  before do
    subject.stub(:require)

    class ::Notifu
      def self.show(options) end
    end
  end

  after { Object.send(:remove_const, :Notifu) if defined?(::Notifu) }

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :notifu notifier runs only on Windows.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'os2'
        subject.available?
      end

      it 'shows an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'mswin'
        ::Guard::UI.should_receive(:error).with "Please add \"gem 'rb-notifu'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('rb-notifu').and_raise LoadError
        subject.available?
      end
    end

    context 'with the silent option' do
      it 'does not show an error message when not available on the host OS' do
        ::Guard::UI.should_not_receive(:error).with 'The :notifu notifier runs only on Windows.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'os2'
        subject.available?(true)
      end

      it 'does not show an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'mswin'
        ::Guard::UI.should_not_receive(:error).with "Please add \"gem 'rb-notifu'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('rb-notifu').and_raise LoadError
        subject.available?(true)
      end
    end
  end

  describe '.nofify' do
    it 'requires the library again' do
      subject.should_receive(:require).with('rb-notifu').and_return true
      subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        ::Notifu.should_receive(:show).with({
            :time    => 3,
            :icon    => false,
            :baloon  => false,
            :nosound => false,
            :noquiet => false,
            :xp      => false,
            :type    => :info,
            :title   => 'Welcome',
            :message => 'Welcome to Guard'
        })
        subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        ::Notifu.should_receive(:show).with({
            :time    => 5,
            :icon    => true,
            :baloon  => true,
            :nosound => true,
            :noquiet => true,
            :xp      => true,
            :type    => :warn,
            :title   => 'Waiting',
            :message => 'Waiting for something'
        })
        subject.notify('pending', 'Waiting', 'Waiting for something', '/tmp/wait.png', {
            :time    => 5,
            :icon    => true,
            :baloon  => true,
            :nosound => true,
            :noquiet => true,
            :xp      => true
        })
      end

      it 'cannot override the core options' do
        ::Notifu.should_receive(:show).with({
            :time    => 3,
            :icon    => false,
            :baloon  => false,
            :nosound => false,
            :noquiet => false,
            :xp      => false,
            :type    => :error,
            :title   => 'Failed',
            :message => 'Something failed'
        })
        subject.notify('failed', 'Failed', 'Something failed', '/tmp/fail.png', {
            :type    => :custom,
            :title   => 'Duplicate title',
            :message => 'Duplicate message'
        })
      end
    end
  end

end
