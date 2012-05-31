module Guard

  # The watcher defines a RegExp that will be matched against file system modifications.
  # When a watcher matches a change, an optional action block is executed to enable
  # processing the file system change result.
  #
  class Watcher

    attr_accessor :pattern, :action

    # Initialize a file watcher.
    #
    # @param [String, Regexp] pattern the pattern to be watched by the guard
    # @param [Block] action the action to execute before passing the result to the Guard
    #
    def initialize(pattern, action = nil)
      @pattern, @action = pattern, action
      @@warning_printed ||= false

      # deprecation warning
      if @pattern.is_a?(String) && @pattern =~ /(^(\^))|(>?(\\\.)|(\.\*))|(\(.*\))|(\[.*\])|(\$$)/
        unless @@warning_printed
          UI.info "*"*20 + "\nDEPRECATION WARNING!\n" + "*"*20
          UI.info <<-MSG
            You have a string in your Guardfile watch patterns that seem to represent a Regexp.
            Guard matches String with == and Regexp with Regexp#match.
            You should either use plain String (without Regexp special characters) or real Regexp.
          MSG
          @@warning_printed = true
        end

        UI.info "\"#{@pattern}\" has been converted to #{ Regexp.new(@pattern).inspect }\n"
        @pattern = Regexp.new(@pattern)
      end
    end

    # Finds the files that matches a Guard.
    #
    # @param [Guard::Guard] guard the guard which watchers are used
    # @param [Array<String>] files the changed files
    # @return [Array<Object>] the matched watcher response
    #
    def self.match_files(guard, files)
      return [] if files.empty?
      guard.watchers.inject([]) do |paths, watcher|
        files.each do |file|
          if matches = watcher.match(file)
            if watcher.action
              result = watcher.call_action(matches)
              if guard.options[:any_return]
                paths << result
              elsif result.respond_to?(:empty?) && !result.empty?
                paths << Array(result)
              end
            else
              paths << matches[0]
            end
          end
        end

        guard.options[:any_return] ? paths : paths.flatten.map { |p| p.to_s }
      end
    end

    # Test if a file would be matched by any of the Guards watchers.
    #
    # @param [Array<Guard::Guard>] guards the guards to use the watchers from
    # @param [Array<String>] files the files to test
    # @return [Boolean] Whether a file matches
    #
    def self.match_files?(guards, files)
      guards.any? do |guard|
        guard.watchers.any? do |watcher|
          files.any? { |file| watcher.match(file) }
        end
      end
    end

    # @deprecated Use .match instead
    #
    def match_file?(file)
      UI.info "Guard::Watcher.match_file? is deprecated, please use Guard::Watcher.match instead."
      match(file)
    end

    # Test the watchers pattern against a file.
    #
    # @param [String] file the file to test
    # @return [Array<String>] an array of matches (or containing a single path if the pattern is a string)
    #
    def match(file)
      f = file
      deleted = file.start_with?('!')
      f = deleted ? f[1..-1] : f
      if @pattern.is_a?(Regexp)
        if m = f.match(@pattern)
          m = m.to_a
          m[0] = file
          m
        end
      else
        f == @pattern ? [file] : nil
      end
    end

    # Test if any of the files is the Guardfile.
    #
    # @param [Array<String>] the files to test
    # @return [Boolean] whether one of these files is the Guardfile
    #
    def self.match_guardfile?(files)
      files.any? { |file| "#{ Dir.pwd }/#{ file }" == Dsl.guardfile_path }
    end

    # Executes a watcher action.
    #
    # @param [String, MatchData] matches the matched path or the match from the Regex
    # @return [String] the final paths
    #
    def call_action(matches)
      begin
        @action.arity > 0 ? @action.call(matches) : @action.call
      rescue Exception => e
        UI.error "Problem with watch action!\n#{ e.message }\n\n#{ e.backtrace.join("\n") }"
      end
    end

  end
end
