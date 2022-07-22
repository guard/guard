# frozen_string_literal: true

require "guard/ui"

require_relative "pattern/matcher"
require_relative "pattern/simple_path"

module Guard
  class Watcher
    # @private
    class Pattern
      def self.create(pattern)
        case pattern
        when String, Pathname
          SimplePath.new(pattern)
        else
          Matcher.new(pattern)
        end
      end
    end
  end
end
