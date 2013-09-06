require 'spec_helper'

describe Guard::Notifier::Notifu do
  let(:notifier) { described_class.new }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'Notifu', double
  end

  describe '.supported_hosts' do
    it { described_class.supported_hosts.should eq %w[mswin mingw] }
  end

  describe '.gem_name' do
    it { described_class.gem_name.should eq 'rb-notifu' }
  end

  describe '.available?' do
    it 'requires rb-notifu' do
      described_class.should_receive(:require_gem_safely)

      described_class.should be_available
    end
  end

  describe '#nofify' do
    context 'without additional options' do
      it 'shows the notification with the default options' do
        ::Notifu.should_receive(:show).with(
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
        ::Notifu.should_receive(:show).with(
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
