# frozen_string_literal: true

module Guard
  class Watcher
    class Pattern
      class Matcher
        attr_reader :matcher

        def initialize(obj)
          @matcher = obj
        end

        def to_s
          matcher.to_s
        end
        alias_method :inspect, :to_s

        # Compare with other matcher
        # @param other [Guard::Watcher::Pattern::Matcher]
        #   other matcher for comparing
        # @return [true, false] equal or not
        def ==(other)
          matcher == other.matcher
        end

        def match(string_or_pathname)
          @matcher.match(normalized(string_or_pathname))
        end

        private

        def normalized(string_or_pathname)
          path = Pathname.new(string_or_pathname).cleanpath
          return path.to_s if @matcher.is_a?(Regexp)

          path
        end
      end
    end
  end
end
