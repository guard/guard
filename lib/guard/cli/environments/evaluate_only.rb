require "guard"

module Guard
  module Cli
    module Environments
      class EvaluateOnly
        def initialize(options)
          @options = options
        end

        def evaluate
          # TODO: check bundler setup first?
          #
          # TODO: it should be easier to pass options created with init
          # directly to evaluator
          #
          # TODO: guardfile/DSL should interact only with a given object, and
          # not global Guard object (setting global state only needed before
          # start() is called)
          #
          Guardfile::Evaluator.new(engine: Guard.init(@options)).evaluate
        rescue \
          Dsl::Error,
          Guardfile::Evaluator::NoPluginsError,
          Guardfile::Evaluator::NoGuardfileError,
          Guardfile::Evaluator::NoCustomGuardfile => e
          UI.error(e.message)
          abort
        end
      end
    end
  end
end
