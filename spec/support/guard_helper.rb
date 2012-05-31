shared_examples_for 'interactor enabled' do
  it 'enables the notifier' do
    described_class::Interactor.should_receive(:fabricate)
    described_class.setup_interactor
  end
end

shared_examples_for 'interactor disabled' do
  it 'enables the notifier' do
    described_class::Interactor.should_not_receive(:fabricate)
    described_class.setup_interactor
  end
end

shared_examples_for 'notifier enabled' do
  it 'enables the notifier' do
    described_class::Notifier.should_receive(:turn_on)
    described_class.setup_notifier
  end
end

shared_examples_for 'notifier disabled' do
  it 'disables the notifier' do
    described_class::Notifier.should_receive(:turn_off)
    described_class.setup_notifier
  end
end
