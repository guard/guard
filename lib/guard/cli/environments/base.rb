# frozen_string_literal: true

require "guard/engine"

module Guard
  module Cli
    module Environments
      class Base
        def initialize(options)
          @options = options
        end

        private

        attr_reader :options
      end
    end
  end
end
