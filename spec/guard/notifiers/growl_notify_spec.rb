require 'spec_helper'

describe Guard::Notifier::GrowlNotify do
  let(:notifier) { described_class.new }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'GrowlNotify', stub
  end

  describe '.supported_hosts' do
    it { described_class.supported_hosts.should eq %w[darwin] }
  end

  describe '.available?' do
    context 'when the application name is not Guard' do
      let(:config) { double('config') }

      it 'does configure GrowlNotify' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::GrowlNotify.should_receive(:application_name).and_return nil
        ::GrowlNotify.should_receive(:config).and_yield config
        config.should_receive(:notifications=).with ['success', 'pending', 'failed', 'notify']
        config.should_receive(:default_notifications=).with 'notify'
        config.should_receive(:application_name=).with 'Guard'

        described_class.should be_available
      end
    end

    context 'when the application name is Guard' do
      it 'does not configure GrowlNotify again' do
        RbConfig::CONFIG.should_receive(:[]).with('host_os').and_return 'darwin'
        ::GrowlNotify.should_receive(:application_name).and_return 'Guard'
        ::GrowlNotify.should_not_receive(:config)

        described_class.should be_available
      end
    end
  end

  describe '#notify' do
    context 'without additional options' do
      it 'shows the notification with the default options' do
        ::GrowlNotify.should_receive(:send_notification).with(
          :sticky           => false,
          :priority         => 0,
          :application_name => 'Guard',
          :with_name        => 'success',
          :title            => 'Welcome',
          :description      => 'Welcome to Guard',
          :icon             => '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', :type => :success, :title => 'Welcome', :image => '/tmp/welcome.png')
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        ::GrowlNotify.should_receive(:send_notification).with(
          :sticky           => true,
          :priority         => -2,
          :application_name => 'Guard',
          :with_name        => 'pending',
          :title            => 'Waiting',
          :description      => 'Waiting for something',
          :icon             => '/tmp/wait.png'
        )

        notifier.notify('Waiting for something', :type => :pending, :title => 'Waiting', :image => '/tmp/wait.png',
          :sticky   => true,
          :priority => -2
        )
      end
    end
  end

end
