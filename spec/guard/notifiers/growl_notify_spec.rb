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
    context 'host is not supported' do
      before { RbConfig::CONFIG.stub(:[]).with('host_os').and_return('mswin') }

      it 'do not require growl_notify' do
        expect(described_class).to_not receive(:require_gem_safely)

        expect(described_class).to_not be_available
      end
    end

    context 'host is supported' do
      before { RbConfig::CONFIG.stub(:[]).with('host_os').and_return('darwin') }

      it 'requires growl_notify' do
        expect(described_class).to receive(:require_gem_safely) { true }
        expect(described_class).to receive(:_register!) { true }

        expect(described_class).to be_available
      end

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

      context '.require_gem_safely fails' do
        before { expect(described_class).to receive(:require_gem_safely) { false } }

        it 'requires growl_notify' do
          expect(described_class).to_not receive(:_register!)

          expect(described_class).to_not be_available
        end
      end

      context '._register! fails' do
        before do
          expect(described_class).to receive(:require_gem_safely) { true }
          expect(described_class).to receive(:_register!) { false }
        end

        it 'requires growl_notify' do
          expect(described_class).to_not be_available
        end
      end
    end
  end

  describe '.available?' do
  end

  describe '#notify' do
    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(title: 'Hello') }

      it 'uses these options by default' do
        expect(::GrowlNotify).to receive(:send_notification).with(
          sticky:           false,
          priority:         0,
          application_name: 'Guard',
          with_name:        'success',
          title:            'Hello',
          description:      'Welcome to Guard',
          icon:             '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', type: :success, image: '/tmp/welcome.png')
      end

      it 'overwrites object options with passed options' do
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
