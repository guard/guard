require 'spec_helper'

describe Guard::Notifier::Notifu do
  let(:notifier) { described_class.new }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'Notifu', double
  end

  describe '.supported_hosts' do
    it { expect(described_class.supported_hosts).to eq %w[mswin mingw] }
  end

  describe '.gem_name' do
    it { expect(described_class.gem_name).to eq 'rb-notifu' }
  end

  describe '.available?' do
    context 'host is not supported' do
      before { RbConfig::CONFIG.stub(:[]).with('host_os').and_return('darwin') }

      it 'do not require rb-notifu' do
        expect(described_class).to_not receive(:require_gem_safely)

        expect(described_class).to_not be_available
      end
    end

    context 'host is supported' do
      before { RbConfig::CONFIG.stub(:[]).with('host_os').and_return('mswin') }

      it 'requires rb-notifu' do
        expect(described_class).to receive(:require_gem_safely) { true }

        expect(described_class).to be_available
      end
    end
  end

  describe '#nofify' do
    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(title: 'Hello', silent: true) }

      it 'uses these options by default' do
        expect(::Notifu).to receive(:show).with(
          time:    3,
          icon:    false,
          baloon:  false,
          nosound: false,
          noquiet: false,
          xp:      false,
          title:   'Hello',
          type:    :info,
          image:   '/tmp/welcome.png',
          message: 'Welcome to Guard'
        )

        notifier.notify('Welcome to Guard', image: '/tmp/welcome.png')
      end

      it 'overwrites object options with passed options' do
        expect(::Notifu).to receive(:show).with(
          time:    3,
          icon:    false,
          baloon:  false,
          nosound: false,
          noquiet: false,
          xp:      false,
          title:   'Welcome',
          type:    :info,
          image:   '/tmp/welcome.png',
          message: 'Welcome to Guard'
        )

        notifier.notify('Welcome to Guard', title: 'Welcome', image: '/tmp/welcome.png')
      end
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        expect(::Notifu).to receive(:show).with(
          time:    3,
          icon:    false,
          baloon:  false,
          nosound: false,
          noquiet: false,
          xp:      false,
          title:   'Welcome',
          type:    :info,
          image:   '/tmp/welcome.png',
          message: 'Welcome to Guard'
        )

        notifier.notify('Welcome to Guard', title: 'Welcome', image: '/tmp/welcome.png')
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        expect(::Notifu).to receive(:show).with(
          time:    5,
          icon:    true,
          baloon:  true,
          nosound: true,
          noquiet: true,
          xp:      true,
          title:   'Waiting',
          type:    :warn,
          image:   '/tmp/wait.png',
          message: 'Waiting for something'
        )

        notifier.notify('Waiting for something',
          time:    5,
          icon:    true,
          baloon:  true,
          nosound: true,
          noquiet: true,
          xp:      true,
          title:   'Waiting',
          type:    :pending,
          image:   '/tmp/wait.png'
        )
      end
    end
  end

end
