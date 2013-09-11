require 'spec_helper'

describe Guard::Notifier::TerminalNotifier do
  let(:notifier) { described_class.new }

  before do
    described_class.stub(:require_gem_safely).and_return(true)
    stub_const 'TerminalNotifier::Guard', double(available?: true)
  end

  describe '.supported_hosts' do
    it { described_class.supported_hosts.should eq %w[darwin ] }
  end

  describe '.gem_name' do
    it { described_class.gem_name.should eq 'terminal-notifier-guard' }
  end

  describe '.available?' do
    it 'requires terminal-notifier-guard' do
      described_class.should_receive(:require_gem_safely)

      described_class.should be_available
    end
  end

  describe '#notify' do
    it 'should call the notifier.' do
      ::TerminalNotifier::Guard.should_receive(:notify).with('any message', title: 'any title', type: :success)

      notifier.notify('any message', title: 'any title')
    end

    it "should allow the title to be customized" do
        ::TerminalNotifier::Guard.should_receive(:notify).with('any message', title: 'any title', type: :error)

      notifier.notify('any message', type: :error, title: 'any title')
    end

    context 'without a title set' do
      it 'should show the app name in the title' do
        ::TerminalNotifier::Guard.should_receive(:notify).with('any message', title: 'FooBar Success', type: :success)

        notifier.notify('any message', title: nil, app_name: 'FooBar')
      end
    end
  end

  describe '#turn_off' do
    it 'should call #remove on the notifier.' do
      ::TerminalNotifier::Guard.should_receive(:remove)

      notifier.turn_off
    end
  end

end
