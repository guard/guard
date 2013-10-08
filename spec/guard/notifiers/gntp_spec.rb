require 'spec_helper'

describe Guard::Notifier::GNTP do
  let(:notifier) { described_class.new }
  let(:gntp) { double('GNTP').as_null_object }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'GNTP', gntp
  end

  describe '.supported_hosts' do
    it { expect(described_class.supported_hosts).to eq %w[darwin linux freebsd openbsd sunos solaris mswin mingw cygwin] }
  end

  describe '.gem_name' do
    it { expect(described_class.gem_name).to eq 'ruby_gntp' }
  end

  describe '.available?' do
    context 'host is not supported' do
      before { RbConfig::CONFIG.stub(:[]).with('host_os').and_return('foobar') }

      it 'do not require ruby_gntp' do
        expect(described_class).to_not receive(:require_gem_safely)

        expect(described_class).to_not be_available
      end
    end

    context 'host is supported' do
      before { RbConfig::CONFIG.stub(:[]).with('host_os').and_return('darwin') }

      it 'requires ruby_gntp' do
        expect(described_class).to receive(:require_gem_safely) { true }

        expect(described_class).to be_available
      end
    end
  end

  describe '#client' do
    before do
      ::GNTP.stub(:new).and_return(gntp)
      gntp.stub(:register)
    end

    it 'creates a new GNTP client and memoize it' do
      expect(::GNTP).to receive(:new).with('Guard', '127.0.0.1', '', 23053).once.and_return(gntp)

      notifier.send(:_client, described_class::DEFAULTS.dup)
      notifier.send(:_client, described_class::DEFAULTS.dup) # 2nd call, memoized
    end

    it 'calls #register on the client and memoize it' do
      expect(::GNTP).to receive(:new).with('Guard', '127.0.0.1', '', 23053).once.and_return(gntp)
      expect(gntp).to receive(:register).once

      notifier.send(:_client, described_class::DEFAULTS.dup)
      notifier.send(:_client, described_class::DEFAULTS.dup) # 2nd call, memoized
    end
  end

  describe '#notify' do
    before { notifier.stub(:_client).and_return(gntp) }

    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(title: 'Hello') }

      it 'uses these options by default' do
        expect(gntp).to receive(:notify).with(
          sticky: false,
          name:   'success',
          title:  'Hello',
          text:   'Welcome to Guard',
          icon:   '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', type: :success, image: '/tmp/welcome.png')
      end

      it 'overwrites object options with passed options' do
        expect(gntp).to receive(:notify).with(
          sticky: false,
          name:   'success',
          title:  'Welcome',
          text:   'Welcome to Guard',
          icon:   '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', type: :success, title: 'Welcome', image: '/tmp/welcome.png')
      end
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        expect(gntp).to receive(:notify).with(
          sticky: false,
          name:   'success',
          title:  'Welcome',
          text:   'Welcome to Guard',
          icon:   '/tmp/welcome.png'
        )

        notifier.notify('Welcome to Guard', type: :success, title: 'Welcome', image: '/tmp/welcome.png')
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        expect(gntp).to receive(:notify).with(
          sticky: true,
          name:   'pending',
          title:  'Waiting',
          text:   'Waiting for something',
          icon:   '/tmp/wait.png'
        )

        notifier.notify('Waiting for something', type: :pending, title: 'Waiting', image: '/tmp/wait.png', sticky: true)
      end
    end
  end

end
