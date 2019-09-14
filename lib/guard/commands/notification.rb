require "pry"

require "guard/notifier"
require "guard/commands/with_engine"

module Guard
  module Commands
    class Notification
      extend WithEngine

      def self.import(engine:)
        super

        Pry::Commands.create_command "notification" do
          group "Guard"
          description "Toggles the notifications."

          banner <<-BANNER
          Usage: notification

          Toggles the notifications on and off.
          BANNER

          def process
            Notifier.toggle
          end
        end
      end
    end
  end
end
