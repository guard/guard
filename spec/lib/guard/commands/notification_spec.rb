require 'spec_helper'

describe Guard::Commands::Notification do
  it 'toggles the Guard notifier' do
    expect(::Guard::Notifier).to receive(:toggle)
    Pry.run_command 'notification'
  end
end
