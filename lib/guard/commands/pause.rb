require "pry"

require "guard/commands/with_engine"

module Guard
  module Commands
    class Pause
      extend WithEngine

      def self.import(engine:)
        super

        Pry::Commands.create_command "pause" do
          group "Guard"
          description "Toggles the file listener."

          banner <<-BANNER
          Usage: pause

          Toggles the file listener on and off.

          When the file listener is paused, the default Guard Pry
          prompt will show the pause sign `[p]`.
          BANNER

          def process
            Pause.engine.async_queue_add([:guard_pause])
          end
        end
      end
    end
  end
end
