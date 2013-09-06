require 'spec_helper'

describe Guard::Notifier::Growl do
  let(:notifier) { described_class.new }
  let(:growl) { double('Growl', installed?: true) }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'Growl', growl
  end

  describe '.supported_hosts' do
    it { described_class.supported_hosts.should eq %w[darwin] }
  end

  describe '.available?' do
    it 'requires growl' do
      described_class.should_receive(:require_gem_safely)

      described_class.should be_available
    end
  end

  describe '#notify' do
    context 'without additional options' do
      it 'shows the notification with the default options' do
        ::Growl.should_receive(:notify).with('Welcome to Guard',
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
        ::Growl.should_receive(:notify).with('Waiting for something',
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
