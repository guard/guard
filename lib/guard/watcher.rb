require "guard/config"
require "guard/deprecated/watcher" unless Guard::Config.new.strict?

require "guard/ui"

module Guard
  # The watcher defines a RegExp that will be matched against file system
  # modifications.
  # When a watcher matches a change, an optional action block is executed to
  # enable processing the file system change result.
  #
  class Watcher
    Deprecated::Watcher.add_deprecated(self) unless Config.new.strict?
    attr_accessor :pattern, :action

    # Initializes a file watcher.
    #
    # @param [String, Regexp] pattern the pattern to be watched by the Guard
    #   plugin
    # @param [Block] action the action to execute before passing the result to
    #   the Guard plugin
    #
    def initialize(pattern, action = nil)
      @pattern, @action = pattern, action
      @@warning_printed ||= false

      # deprecation warning
      regexp = /(^(\^))|(>?(\\\.)|(\.\*))|(\(.*\))|(\[.*\])|(\$$)/
      return unless @pattern.is_a?(String) && @pattern =~ regexp

      unless @@warning_printed
        UI.info "*" * 20 + "\nDEPRECATION WARNING!\n" + "*" * 20
        UI.info <<-MSG
            You have a string in your Guardfile watch patterns that seem to
            represent a Regexp.

            Guard matches String with == and Regexp with Regexp#match.

            You should either use plain String (without Regexp special
            characters) or real Regexp.
        MSG
        @@warning_printed = true
      end

      new_regexp = Regexp.new(@pattern).inspect
      UI.info "\"#{@pattern}\" has been converted to #{ new_regexp }\n"
      @pattern = Regexp.new(@pattern)
    end

    # Finds the files that matches a Guard plugin.
    #
    # @param [Guard::Plugin] guard the Guard plugin which watchers are used
    # @param [Array<String>] files the changed files
    # @return [Array<Object>] the matched watcher response
    #
    def self.match_files(guard, files)
      return [] if files.empty?

      files.inject([]) do |paths, file|
        guard.watchers.each do |watcher|
          matches = watcher.match(file)
          next unless matches

          if watcher.action
            result = watcher.call_action(matches)
            if guard.options[:any_return]
              paths << result
            elsif result.respond_to?(:empty?) && !result.empty?
              paths << Array(result)
            else
              next
            end
          else
            paths << matches[0]
          end

          break if guard.options[:first_match]
        end

        guard.options[:any_return] ? paths : paths.flatten.map(&:to_s)
      end
    end

    # Test the watchers pattern against a file.
    #
    # @param [String] file the file to test
    # @return [Array<String>] an array of matches (or containing a single path
    #   if the pattern is a string)
    #
    def match(string_or_pathname)
      # TODO: use only match() - and show fnmatch example
      file = string_or_pathname.to_s
      return (file == @pattern ? [file] : nil) unless @pattern.is_a?(Regexp)
      return unless (m = @pattern.match(file))
      m = m.to_a
      m[0] = file
      m
    end

    # Executes a watcher action.
    #
    # @param [String, MatchData] matches the matched path or the match from the
    #   Regex
    # @return [String] the final paths
    #
    def call_action(matches)
      @action.arity > 0 ? @action.call(matches) : @action.call
    rescue => ex
      UI.error "Problem with watch action!\n#{ ex.message }"
      UI.error ex.backtrace.join("\n")
    end
  end
end
