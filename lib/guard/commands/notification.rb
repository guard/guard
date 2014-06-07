require 'guard/notifier'

module Guard
  # Command to toggle notifications on and off
  class Interactor
    NOTIFICATION = Pry::CommandSet.new do
      create_command 'notification' do

        group 'Guard'
        description 'Toggles the notifications.'

        banner <<-BANNER
          Usage: notification

          Toggles the notifications on and off.
        BANNER

        def process
          ::Guard::Notifier.toggle
        end
      end
    end
  end
end

Pry.commands.import ::Guard::Interactor::NOTIFICATION
