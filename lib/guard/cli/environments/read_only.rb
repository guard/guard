# frozen_string_literal: true

require "guard/cli/environments/base"
require "guard/dsl"
require "guard/engine"
require "guard/guardfile/evaluator"
require "guard/ui"

module Guard
  module Cli
    module Environments
      class ReadOnly < Base
        def evaluate(evaluator: Guardfile::Evaluator.new(options))
          bundler_check
          evaluator.evaluate
        rescue Dsl::Error,
               Guardfile::Evaluator::NoGuardfileError,
               Guardfile::Evaluator::NoCustomGuardfile => e

          UI.error(e.message)
          abort("")
        end

        def start(engine: Guard::Engine.new(options))
          bundler_check
          engine.start
        rescue Dsl::Error,
               Guardfile::Evaluator::NoGuardfileError,
               Guardfile::Evaluator::NoCustomGuardfile => e

          # catch to throw message instead of call stack
          UI.error(e.message)
          abort("")
        end
      end
    end
  end
end
