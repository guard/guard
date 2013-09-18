require 'spec_helper'

describe Guard::Notifier::GrowlNotify do
  let(:notifier) { described_class.new }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'GrowlNotify', double
  end

  describe '.supported_hosts' do
    it { expect(described_class.supported_hosts).to eq %w[darwin] }
  end

  describe '.available?' do
    context 'when the application name is not Guard' do
      let(:config) { double('config') }

      it 'does configure GrowlNotify' do
        expect(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return 'darwin'
        expect(::GrowlNotify).to receive(:application_name).and_return nil
        expect(::GrowlNotify).to receive(:config).and_yield config
        expect(config).to receive(:notifications=).with ['success', 'pending', 'failed', 'notify']
        expect(config).to receive(:default_notifications=).with 'notify'
        expect(config).to receive(:application_name=).with 'Guard'

        expect(described_class).to be_available
      end
    end

    context 'when the application name is Guard' do
      it 'does not configure GrowlNotify again' do
        expect(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return 'darwin'
        expect(::GrowlNotify).to receive(:application_name).and_return 'Guard'
        expect(::GrowlNotify).to_not receive(:config)

        expect(described_class).to be_available
      end
    end
  end

  describe '#notify' do
    context 'without additional options' do
      it 'shows the notification with the default options' do
        expect(::GrowlNotify).to receive(:send_notification).with(
          sticky:           false,
          priority:         0,
          application_name: 'Guard',
          with_name:        'success',
          title:            'Welcome',
          description:      'Welcome to Guard',
          icon:             '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', type: :success, title: 'Welcome', image: '/tmp/welcome.png')
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        expect(::GrowlNotify).to receive(:send_notification).with(
          sticky:           true,
          priority:         -2,
          application_name: 'Guard',
          with_name:        'pending',
          title:            'Waiting',
          description:      'Waiting for something',
          icon:             '/tmp/wait.png'
        )

        notifier.notify('Waiting for something', type: :pending, title: 'Waiting', image: '/tmp/wait.png',
          sticky:   true,
          priority: -2
        )
      end
    end
  end

end
