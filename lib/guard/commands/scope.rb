# frozen_string_literal: true

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

          def engine # rubocop:disable Lint/NestedMethodDefinition
            Thread.current[:engine]
          end

          def process(*entries) # rubocop:disable Lint/NestedMethodDefinition
            session = engine.session
            scopes, unknown = session.convert_scopes(entries)

            if unknown.any?
              output.puts "Unknown scopes: #{unknown.join(',')}"
              return
            end

            if scopes[:plugins].empty? && scopes[:groups].empty?
              output.puts "Usage: scope <scope>"
              return
            end

            session.interactor_scopes = scopes
          end
        end
      end
    end
  end
end
