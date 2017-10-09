require "pry"

require "guard/commands/with_engine"

module Guard
  module Commands
    class Scope
      extend WithEngine

      def self.import(engine:)
        super

        Pry::Commands.create_command "scope" do
          group "Guard"
          description "Scope Guard actions to groups and plugins."

          banner <<-BANNER
          Usage: scope <scope>

          Set the global Guard scope.
          BANNER

          def process(*entries)
            scope, unknown = Scope.engine.session.convert_scope(entries)

            unless unknown.empty?
              output.puts "Unknown scopes: #{unknown.join(',') }"
              return
            end

            if scope[:plugins].empty? && scope[:groups].empty?
              output.puts "Usage: scope <scope>"
              return
            end

            Scope.engine.scope.from_interactor(scope)
          end
        end
      end
    end
  end
end
