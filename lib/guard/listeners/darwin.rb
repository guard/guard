module Guard
  class Darwin < Listener
    attr_reader :fsevent
    
    def initialize
      super
      @fsevent = FSEvent.new
      fsevent.watch Dir.pwd do |modified_dirs|
        @changed_files += find_changed_files(modified_dirs)
        update_last_event
      end
    end
    
    def start
      # keep relaunching fsevent.run if not stopped by Guard
      while @stop != true
        fsevent.run
      end
    end
    
    def stop
      @stop = true
      fsevent.stop
    end
    
    def self.usable?
      require 'rb-fsevent'
      if !defined?(FSEvent::VERSION) || Gem::Version.new(FSEvent::VERSION) < Gem::Version.new('0.3.9')
        UI.info "Please update rb-fsevent (>= 0.3.9)"
        false
      else
        true
      end
    rescue LoadError
      UI.info "Please install rb-fsevent gem for Mac OSX FSEvents support"
      false
    end
    
  end
end