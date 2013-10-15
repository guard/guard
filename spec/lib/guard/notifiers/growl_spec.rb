require 'spec_helper'

describe Guard::Notifier::Growl do
  let(:notifier) { described_class.new }
  let(:growl) { double('Growl', installed?: true) }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'Growl', growl
  end

  describe '.supported_hosts' do
    it { expect(described_class.supported_hosts).to eq %w[darwin] }
  end

  describe '.available?' do
    context 'host is not supported' do
      before { RbConfig::CONFIG.stub(:[]).with('host_os').and_return('mswin') }

      it 'do not require growl' do
        expect(described_class).to_not receive(:require_gem_safely)

        expect(described_class).to_not be_available
      end
    end

    context 'host is supported' do
      before { RbConfig::CONFIG.stub(:[]).with('host_os').and_return('darwin') }

      it 'requires growl' do
        expect(described_class).to receive(:require_gem_safely) { true }
        expect(described_class).to receive(:_register!) { true }

        expect(described_class).to be_available
      end

      context '.require_gem_safely fails' do
        before { expect(described_class).to receive(:require_gem_safely) { false } }

        it 'requires growl' do
          expect(described_class).to_not receive(:_register!)

          expect(described_class).to_not be_available
        end
      end

      context '._register! fails' do
        before do
          expect(described_class).to receive(:require_gem_safely) { true }
          expect(described_class).to receive(:_register!) { false }
        end

        it 'requires growl' do
          expect(described_class).to_not be_available
        end
      end
    end
  end

  describe '#notify' do
    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(title: 'Hello', silent: true) }

      it 'uses these options by default' do
        expect(::Growl).to receive(:notify).with('Welcome to Guard',
          sticky:   false,
          priority: 0,
          name:     'Guard',
          title:    'Hello',
          image:    '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', image: '/tmp/welcome.png')
      end

      it 'overwrites object options with passed options' do
        expect(::Growl).to receive(:notify).with('Welcome to Guard',
          sticky:   false,
          priority: 0,
          name:     'Guard',
          title:    'Welcome',
          image:    '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', title: 'Welcome', image: '/tmp/welcome.png')
      end
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        expect(::Growl).to receive(:notify).with('Welcome to Guard',
          sticky:   false,
          priority: 0,
          name:     'Guard',
          title:    'Welcome',
          image:    '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', title: 'Welcome', image: '/tmp/welcome.png')
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        expect(::Growl).to receive(:notify).with('Waiting for something',
          sticky:   true,
          priority: 2,
          name:     'Guard',
          title:    'Waiting',
          image:    '/tmp/wait.png'
        )

        notifier.notify('Waiting for something', type: :pending, title: 'Waiting', image: '/tmp/wait.png',
          sticky:   true,
          priority: 2
        )
      end
    end
  end

end
