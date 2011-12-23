require 'spec_helper'

describe Guard::Notifier::Growl do
  before(:all) { Object.send(:remove_const, :Growl) if defined?(::Growl) }

  before do
    subject.stub(:require)

    class ::Growl
      def self.notify(message, options) end
      def self.installed?; end
    end
  end

  after { Object.send(:remove_const, :Growl) if defined?(::Growl) }

  describe '.available?' do
    context 'without the silent option' do
      it 'shows an error message when not available on the host OS' do
        ::Guard::UI.should_receive(:error).with 'The :growl notifier runs only on Mac OS X.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'linux'
        subject.available?
      end

      it 'shows an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::Guard::UI.should_receive(:error).with "Please add \"gem 'growl'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('growl').and_raise LoadError
        subject.available?
      end

      it 'shows an error message when the growlnotify executable cannot be found' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::Guard::UI.should_receive(:error).with "Please install the 'growlnotify' executable."
        ::Growl.should_receive(:installed?).and_return false
        subject.available?
      end
    end

    context 'with the silent option' do
      it 'does not show an error message when not available on the host OS' do
        ::Guard::UI.should_not_receive(:error).with 'The :growl notifier runs only on Mac OS X.'
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'linux'
        subject.available?(true)
      end

      it 'does not show an error message when the gem cannot be loaded' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::Guard::UI.should_not_receive(:error).with "Please add \"gem 'growl'\" to your Gemfile and run Guard with \"bundle exec\"."
        subject.should_receive(:require).with('growl').and_raise LoadError
        subject.available?(true)
      end

      it 'does not show an error message when the growlnotify executable cannot be found' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::Guard::UI.should_not_receive(:error).with "Please install the 'growlnotify' library."
        ::Growl.should_receive(:installed?).and_return false
        subject.available?(true)
      end
    end
  end

  describe '.nofify' do
    it 'requires the library again' do
      subject.should_receive(:require).with('growl').and_return true
      subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        ::Growl.should_receive(:notify).with('Welcome to Guard', {
          :sticky   => false,
          :priority => 0,
          :name     => 'Guard',
          :title    => 'Welcome',
          :image    => '/tmp/welcome.png'
        })
        subject.notify('success', 'Welcome', 'Welcome to Guard', '/tmp/welcome.png', { })
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        ::Growl.should_receive(:notify).with('Waiting for something', {
            :sticky   => true,
            :priority => 2,
            :name     => 'Guard',
            :title    => 'Waiting',
            :image    => '/tmp/wait.png'
        })
        subject.notify('pending', 'Waiting', 'Waiting for something', '/tmp/wait.png', {
            :sticky   => true,
            :priority => 2
        })
      end

      it 'cannot override the core options' do
        ::Growl.should_receive(:notify).with('Something failed', {
          :sticky   => false,
          :priority => 0,
          :name     => 'Guard',
          :title    => 'Failed',
          :image    => '/tmp/fail.png'
        })
        subject.notify('failed', 'Failed', 'Something failed', '/tmp/fail.png', {
            :name  => 'custom',
            :title => 'Duplicate title',
            :image => 'Duplicate image'
        })
      end
    end
  end

end
