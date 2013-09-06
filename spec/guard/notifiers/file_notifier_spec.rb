require 'spec_helper'

describe Guard::Notifier::FileNotifier do
  let(:notifier) { described_class.new }

  describe '.available?' do
    it 'is true if there is a file in options' do
      described_class.should be_available(path: '.guard_result')
    end

    it 'is false if there is no path in options' do
      described_class.should_not be_available
    end
  end

  describe '.notify' do
    it 'writes to a file on success' do
      File.should_receive(:write).with('tmp/guard_result', "success\nany title\nany message\n")

      notifier.notify('any message', title: 'any title', path: 'tmp/guard_result')
    end

    it 'also writes to a file on failure' do
      File.should_receive(:write).with('tmp/guard_result', "failed\nany title\nany message\n")

      notifier.notify('any message',type: :failed, title: 'any title', path: 'tmp/guard_result')
    end

    # We don't have a way to return false in .available? when no path is
    # specified. So, we just don't do anything in .notify if there's no path.
    it 'does not write to a file if no path is specified' do
      File.should_not_receive(:write)
      ::Guard::UI.should_receive(:error).with ":file notifier requires a :path option"

      notifier.notify('any message')
    end
  end

end
