# frozen_string_literal: true

require "pry"

module Guard
  module Commands
    class Reload
      def self.import
        Pry::Commands.create_command "reload" do
          group "Guard"
          description "Reload all plugins."

          banner <<-BANNER
          Usage: reload <scope>

          Run the Guard plugin `reload` action.

          You may want to specify an optional scope to the action,
          either the name of a Guard plugin or a plugin group.
          BANNER

          def engine # rubocop:disable Lint/NestedMethodDefinition
            Thread.current[:engine]
          end

          def process(*entries) # rubocop:disable Lint/NestedMethodDefinition
            engine.async_queue_add([:guard_reload, entries])
          end
        end
      end
    end
  end
end
