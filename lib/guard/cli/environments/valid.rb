# frozen_string_literal: true

require "guard/cli/environments/base"
require "guard/cli/environments/bundler"
require "guard/dsl"
require "guard/guardfile/evaluator"
require "guard/guardfile/generator"

module Guard
  module Cli
    module Environments
      class Valid < Base
        def start_engine
          Bundler.new.verify unless options[:no_bundler_warning]
          engine = Guard::Engine.new(options)
          engine.start
        rescue Dsl::Error,
               Guardfile::Evaluator::NoGuardfileError,
               Guardfile::Evaluator::NoCustomGuardfile => e
          # catch to throw message instead of call stack
          UI.error(e.message)
          abort
        ensure
          # `engine` can be nil if `Bundler.new.verify` raises a `SystemExit` error.
          engine&.stop
        end

        def initialize_guardfile(plugin_names = [])
          evaluator = Guardfile::Evaluator.new(options)
          generator = Guardfile::Generator.new(evaluator)
          begin
            evaluator.evaluate
          rescue Guardfile::Evaluator::NoGuardfileError
            generator.create_guardfile
          end

          return 0 if options[:bare] # 0 - exit code

          begin
            if plugin_names.empty?
              generator.initialize_all_templates
            else
              plugin_names.each do |plugin_name|
                generator.initialize_template(plugin_name)
              end
            end
          rescue Guardfile::Generator::Error => e
            UI.error(e.message)
            return 1
          end

          0
        rescue StandardError => e
          UI.error(e.message)
          1
        end
      end
    end
  end
end
