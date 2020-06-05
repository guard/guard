# frozen_string_literal: true

require "guard/engine"

module Guard
  module Cli
    module Environments
      class Base
        attr_reader :engine

        def initialize(options)
          @options = options
          @engine = Guard::Engine.new(options)
        end

        private

        attr_reader :options
      end
    end
  end
end
