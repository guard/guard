shared_examples_for 'interactor enabled' do
  it 'enables the interactor' do
    Guard::Interactor.should_receive(:new)
    Guard.setup_interactor
  end
end

shared_examples_for 'interactor disabled' do
  it 'disables the interactor' do
    Guard::Interactor.should_not_receive(:new)
    Guard.setup_interactor
  end
end

shared_examples_for 'notifier enabled' do
  it 'enables the notifier' do
    Guard::Notifier.should_receive(:turn_on)
    Guard.setup_notifier
  end
end

shared_examples_for 'notifier disabled' do
  it 'disables the notifier' do
    Guard::Notifier.should_receive(:turn_off)
    Guard.setup_notifier
  end
end
