module Guard
  class Guard
    attr_accessor :watchers, :options
    
    def initialize(watchers = [], options = {})
      @watchers, @options = watchers, options
    end
    
    # ================
    # = Guard method =
    # ================
    
    def start
      true
    end
    
    def stop
      true
    end
    
    def reload
      true
    end
    
    def run_all
      true
    end
    
    def run_on_change(paths)
      true
    end
    
  end
end