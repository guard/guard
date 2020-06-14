# frozen_string_literal: true

require "guard/cli/environments/base"
require "guard/cli/environments/bundler"
require "guard/dsl"
require "guard/guardfile/evaluator"
require "guard/ui"

module Guard
  module Cli
    module Environments
      class EvaluateOnly < Base
        def evaluate
          Bundler.new.verify unless options[:no_bundler_warning]
          Guardfile::Evaluator.new(options).evaluate
        rescue \
          Guard::Dsl::Error,
          Guardfile::Evaluator::NoGuardfileError,
          Guardfile::Evaluator::NoCustomGuardfile => e
          UI.error(e.message)
          abort
        end
      end
    end
  end
end
