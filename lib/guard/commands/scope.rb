require "pry"

module Guard
  module Commands
    class Scope
      def self.import
        Pry::Commands.create_command "scope" do
          group "Guard"
          description "Scope Guard actions to groups and plugins."

          banner <<-BANNER
          Usage: scope <scope>

          Set the global Guard scope.
          BANNER

          def process(*entries)
            scope, unknown = ::Guard::Interactor.convert_scope(entries)

            unless unknown.empty?
              output.puts "Unknown scopes: #{unknown.join(",") }"
              return
            end

            if scope[:plugins].empty? && scope[:groups].empty?
              output.puts "Usage: scope <scope>"
              return
            end

            ::Guard.setup_scope(scope)
          end
        end
      end
    end
  end
end
