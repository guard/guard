require "pry"

require "guard/commands/with_engine"

module Guard
  module Commands
    class All
      extend WithEngine

      def self.import(engine:)
        super

        Pry::Commands.create_command "all" do
          group "Guard"
          description "Run all plugins."

          banner <<-BANNER
          Usage: all <scope>

          Run the Guard plugin `run_all` action.

          You may want to specify an optional scope to the action,
          either the name of a Guard plugin or a plugin group.
          BANNER

          def process(*entries)
            scopes, unknown = All.engine.session.convert_scope(entries)

            unless unknown.empty?
              output.puts "Unknown scopes: #{ unknown.join(', ') }"
              return
            end

            All.engine.async_queue_add([:guard_run_all, scopes])
          end
        end
      end
    end
  end
end
