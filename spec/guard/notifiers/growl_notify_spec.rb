require 'spec_helper'

describe Guard::Notifier::GrowlNotify do
  before(:all) { Object.send(:remove_const, :GrowlNotify) if defined?(::GrowlNotify) }

  before do
    subject.stub(:require)

    class ::GrowlNotify
      def self.application_name; end
      def self.send_notification(options) end
    end
  end

  after { Object.send(:remove_const, :GrowlNotify) if defined?(::GrowlNotify) }

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :growl_notify notifier runs only on Mac OS X.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'mswin'
        subject.available?
      end

      it 'shows an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::Guard::UI.should_receive(:error).with "Please add \"gem 'growl_notify'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('growl_notify').and_raise LoadError
        subject.available?
      end
    end

    context 'with the silent option' do
      it 'does not show an error message when not available on the host OS' do
        ::Guard::UI.should_not_receive(:error).with 'The :growl_notify notifier runs only on Mac OS X.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'mswin'
        subject.available?(true)
      end

      it 'does not show an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::Guard::UI.should_not_receive(:error).with "Please add \"gem 'growl_notify'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('growl_notify').and_raise LoadError
        subject.available?(true)
      end
    end

    context 'when the application name is not Guard' do
      let(:config) { mock('config') }

      it 'does configure GrowlNotify' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::GrowlNotify.should_receive(:application_name).and_return nil
        ::GrowlNotify.should_receive(:config).and_yield config
        config.should_receive(:notifications=).with ['success', 'pending', 'failed', 'notify']
        config.should_receive(:default_notifications=).with 'notify'
        config.should_receive(:application_name=).with 'Guard'
        subject.available?
      end
    end

    context 'when the application name is Guard' do
      it 'does not configure GrowlNotify again' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::GrowlNotify.should_receive(:application_name).and_return 'Guard'
        ::GrowlNotify.should_not_receive(:config)
        subject.available?
      end
    end

  end

  describe '.nofify' do
    it 'requires the library again' do
      subject.should_receive(:require).with('growl_notify').and_return true
      subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        ::GrowlNotify.should_receive(:send_notification).with({
            :sticky           => false,
            :priority         => 0,
            :application_name => 'Guard',
            :with_name        => 'success',
            :title            => 'Welcome',
            :description      => 'Welcome to Guard',
            :icon             => '/tmp/welcome.png'
        })
        subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        ::GrowlNotify.should_receive(:send_notification).with({
            :sticky           => true,
            :priority         => -2,
            :application_name => 'Guard',
            :with_name        => 'pending',
            :title            => 'Waiting',
            :description      => 'Waiting for something',
            :icon             => '/tmp/wait.png'
        })
        subject.notify('pending', 'Waiting', 'Waiting for something', '/tmp/wait.png', {
            :sticky   => true,
            :priority => -2
        })
      end

      it 'cannot override the core options' do
        ::GrowlNotify.should_receive(:send_notification).with({
            :sticky           => false,
            :priority         => 0,
            :application_name => 'Guard',
            :with_name        => 'failed',
            :title            => 'Failed',
            :description      => 'Something failed',
            :icon             => '/tmp/fail.png'
        })
        subject.notify('failed', 'Failed', 'Something failed', '/tmp/fail.png', {
            :application_name => 'Guard CoffeeScript',
            :with_name        => 'custom',
            :title            => 'Duplicate title',
            :description      => 'Duplicate description',
            :icon             => 'Duplicate icon'
        })
      end
    end
  end

end
