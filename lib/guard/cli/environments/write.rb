# frozen_string_literal: true

require "guard/cli/environments/base"
require "guard/guardfile/evaluator"
require "guard/guardfile/generator"
require "guard/ui"

module Guard
  module Cli
    module Environments
      class Write < Base
        def initialize_guardfile(
          plugin_names = [],
          evaluator: Guardfile::Evaluator.new(options),
          generator: Guardfile::Generator.new
        )
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
