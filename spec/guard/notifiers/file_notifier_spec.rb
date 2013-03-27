require 'spec_helper'


describe Guard::Notifier::FileNotifier do

  describe '.available?' do
    it 'is always true' do
      subject.should be_available
    end
  end

  describe '.notify' do
    it 'writes to a file on success' do
      subject.should_receive(:write).with('tmp/guard_result', "success\nany title\nany message\n")

      subject.notify('success', 'any title', 'any message', 'any image', { path: 'tmp/guard_result' })
    end

    it 'also writes to a file on failure' do
      subject.should_receive(:write).with('tmp/guard_result', "failed\nany title\nany message\n")

      subject.notify('failed', 'any title', 'any message', 'any image', { path: 'tmp/guard_result' })
    end

    # We don't have a way to return false in .available? when no path is
    # specified. So, we just don't do anything in .notify if there's no path.
    it 'does not write to a file if no path is specified' do
      subject.should_not_receive(:write)

      subject.notify('success', 'any title', 'any message', 'any image', { })
    end
  end
end
