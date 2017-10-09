require "pry"

require "guard/commands/with_engine"

module Guard
  module Commands
    class Show
      extend WithEngine

      def self.import(engine:)
        super

        Pry::Commands.create_command "show" do
          group "Guard"
          description "Show all Guard plugins."

          banner <<-BANNER
          Usage: show

          Show all defined Guard plugins and their options.
          BANNER

          def process
            Show.engine.async_queue_add([:guard_show])
          end
        end
      end
    end
  end
end
