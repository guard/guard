# frozen_string_literal: true

module Guard
  class Watcher
    class Pattern
      class SimplePath
        def initialize(string_or_pathname)
          @path = normalize(string_or_pathname)
        end

        def to_s
          @path
        end
        alias_method :inspect, :to_s

        def match(string_or_pathname)
          cleaned = normalize(string_or_pathname)
          return nil unless @path == cleaned

          [cleaned]
        end

        protected

        def normalize(string_or_pathname)
          Pathname.new(string_or_pathname).cleanpath.to_s
        end
      end
    end
  end
end
