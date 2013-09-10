require 'spec_helper'

describe Guard::Notifier::GNTP do
  let(:notifier) { described_class.new }
  let(:gntp) { double('GNTP').as_null_object }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'GNTP', gntp
  end

  describe '.supported_hosts' do
    it { described_class.supported_hosts.should eq %w[darwin linux freebsd openbsd sunos solaris mswin mingw cygwin] }
  end

  describe '.gem_name' do
    it { described_class.gem_name.should eq 'ruby_gntp' }
  end

  describe '.available?' do
    it 'requires ruby_gntp' do
      described_class.should_receive(:require_gem_safely)

      described_class.should be_available
    end
  end

  describe '#client' do
    before do
      ::GNTP.stub(:new).and_return(gntp)
      gntp.stub(:register)
    end

    it 'creates a new GNTP client and memoize it' do
      ::GNTP.should_receive(:new).with('Guard', '127.0.0.1', '', 23053).once.and_return(gntp)

      notifier.send(:_client, described_class::DEFAULTS.dup)
      notifier.send(:_client, described_class::DEFAULTS.dup) # 2nd call, memoized
    end

    it 'calls #register on the client and memoize it' do
      ::GNTP.should_receive(:new).with('Guard', '127.0.0.1', '', 23053).once.and_return(gntp)
      gntp.should_receive(:register).once

      notifier.send(:_client, described_class::DEFAULTS.dup)
      notifier.send(:_client, described_class::DEFAULTS.dup) # 2nd call, memoized
    end
  end

  describe '#notify' do
    before { notifier.stub(:_client).and_return(gntp) }

    context 'without additional options' do

      it 'shows the notification with the default options' do
        gntp.should_receive(:notify).with(
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
        gntp.should_receive(:notify).with(
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
