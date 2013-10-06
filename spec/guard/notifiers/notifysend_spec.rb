require 'spec_helper'

describe Guard::Notifier::NotifySend do
  let(:notifier) { described_class.new }

  before do
    stub_const 'NotifySend', double
  end

  describe '.supported_hosts' do
    it { expect(described_class.supported_hosts).to eq %w[linux freebsd openbsd sunos solaris] }
  end

  describe '.available?' do
    it 'checks if the binary is available' do
      expect(described_class).to receive(:_notifysend_binary_available?)

      expect(described_class).to be_available
    end
  end

  describe '#notify' do
    context 'with options passed at initialization' do
      let(:notifier) { described_class.new(image: '/tmp/hello.png') }

      it 'uses these options by default' do
        notifier.should_receive(:system).with do |command, *arguments|
          expect(command).to eql 'notify-send'
          expect(arguments).to include '-i', '/tmp/hello.png'
          expect(arguments).to include '-u', 'low'
          expect(arguments).to include '-t', '3000'
          expect(arguments).to include '-h', 'int:transient:1'
        end

        notifier.notify('Welcome to Guard')
      end

      it 'overwrites object options with passed options' do
        notifier.should_receive(:system).with do |command, *arguments|
          expect(command).to eql 'notify-send'
          expect(arguments).to include '-i', '/tmp/welcome.png'
          expect(arguments).to include '-u', 'low'
          expect(arguments).to include '-t', '3000'
          expect(arguments).to include '-h', 'int:transient:1'
        end

        notifier.notify('Welcome to Guard', image: '/tmp/welcome.png')
      end
    end

    context 'without additional options' do
      it 'shows the notification with the default options' do
        notifier.should_receive(:system).with do |command, *arguments|
          expect(command).to eql 'notify-send'
          expect(arguments).to include '-i', '/tmp/welcome.png'
          expect(arguments).to include '-u', 'low'
          expect(arguments).to include '-t', '3000'
          expect(arguments).to include '-h', 'int:transient:1'
        end

        notifier.notify('Welcome to Guard', image: '/tmp/welcome.png')
      end
    end

    context 'with additional options' do
      it 'can override the default options' do
        notifier.should_receive(:system).with do |command, *arguments|
          expect(command).to eql 'notify-send'
          expect(arguments).to include '-i', '/tmp/wait.png'
          expect(arguments).to include '-u', 'critical'
          expect(arguments).to include '-t', '5'
        end

        notifier.notify('Waiting for something', type: :pending, image: '/tmp/wait.png',
          t: 5,
          u: :critical
        )
      end
    end

  end

end
