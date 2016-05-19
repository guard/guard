module Guard
  class Watcher
    class Pattern
      class Matcher
        def initialize(obj)
          @matcher = obj
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
