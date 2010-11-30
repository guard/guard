module Guard
  class Watcher
    attr_accessor :pattern, :action
    
    def initialize(pattern, action = nil)
      @pattern, @action = pattern, action
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
      file.match(@pattern)
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