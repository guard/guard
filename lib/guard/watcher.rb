module Guard
  class Watcher
    attr_accessor :pattern, :action
    
    def initialize(pattern, action = nil)
      @pattern, @action = pattern, action
    end
    
    def self.match_files(guard, files)
      guard.watchers.inject([]) do |paths, watcher|
        files.each do |file|
          if matches = file.match(watcher.pattern)
            if watcher.action
              begin 
                if watcher.action.arity == 1
                  result = watcher.action.call(matches)
                else
                  result = watcher.action.call
                end
              rescue
                UI.info "Problem with watch action"
              end
              paths << result if result.is_a?(String) && result != ''
            else
              paths << matches[0]
            end
          end
        end
        paths
      end
    end
    
  end
end