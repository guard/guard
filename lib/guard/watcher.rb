module Guard
  class Watcher
    attr_accessor :pattern, :action
    
    def initialize(pattern, action = nil)
      @pattern, @action = pattern, action
      @@warning_printed ||= false
      
      # deprecation warning
      if @pattern.is_a?(String) && @pattern =~ /(^(\^))|(>?(\\\.)|(\.\*))|(\(.*\))|(\[.*\])|(\$$)/
        unless @@warning_printed
          UI.info "*"*20 + "\nDEPRECATION WARNING!\n" + "*"*20
          UI.info "You have strings in your Guardfile's watch patterns that seem to represent regexps.\nGuard matchs String with == and Regexp with Regexp#match.\nYou should either use plain String (without Regexp special characters) or real Regexp.\n"
          @@warning_printed = true
        end
        UI.info "\"#{@pattern}\" has been converted to #{Regexp.new(@pattern).inspect}\n"
        @pattern = Regexp.new(@pattern)
      end
    end
    
    def self.match_files(guard, files)
      guard.watchers.inject([]) do |paths, watcher|
        files.each do |file|
          if matches = watcher.match_file?(file)
            if watcher.action
              result = watcher.call_action(matches)
              paths << Array(result) if result.respond_to?(:empty?) && !result.empty?
            else
              paths << matches[0]
            end
          end
        end
        paths.flatten.map { |p| p.to_s }
      end
    end
    
    def self.match_files?(guards, files)
      guards.any? do |guard|
        guard.watchers.any? do |watcher|
          files.any? { |file| watcher.match_file?(file) }
        end
      end
    end
    
    def match_file?(file)
      if @pattern.is_a?(Regexp)
        file.match(@pattern)
      else
        file == @pattern ? [file] : nil
      end
    end
    
    def call_action(matches)
      begin
        @action.arity > 0 ? @action.call(matches) : @action.call
      rescue
        UI.error "Problem with watch action!"
      end
    end
    
  end
end