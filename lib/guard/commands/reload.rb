require "pry"

require "guard/commands/with_engine"

module Guard
  module Commands
    class Reload
      extend WithEngine

      def self.import(engine:)
        super

        Pry::Commands.create_command "reload" do
          group "Guard"
          description "Reload all plugins."

          banner <<-BANNER
          Usage: reload <scope>

          Run the Guard plugin `reload` action.

          You may want to specify an optional scope to the action,
          either the name of a Guard plugin or a plugin group.
          BANNER

          def process(*entries)
            scopes, unknown = Reload.engine.session.convert_scope(entries)

            unless unknown.empty?
              output.puts "Unknown scopes: #{ unknown.join(', ') }"
              return
            end

            Reload.engine.async_queue_add([:guard_reload, scopes])
          end
        end
      end
    end
  end
end
