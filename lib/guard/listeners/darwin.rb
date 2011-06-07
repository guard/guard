module Guard
  class Darwin < Listener
    attr_reader :fsevent

    def initialize(*)
      super
      @fsevent = FSEvent.new
    end

    def worker
      @fsevent
    end

    def start
      super
      fsevent.run
    end

    def stop
      super
      fsevent.stop
    end

    def self.usable?
      require 'rb-fsevent'
      if !defined?(FSEvent::VERSION) || (defined?(Gem::Version) &&
          Gem::Version.new(FSEvent::VERSION) < Gem::Version.new('0.4.0'))
        UI.info "Please update rb-fsevent (>= 0.4.0)"
        false
      else
        true
      end
    rescue LoadError
      UI.info "Please install rb-fsevent gem for Mac OSX FSEvents support"
      false
    end

  private

    def watch(directory)
      worker.watch directory do |modified_dirs|
        files = modified_files(modified_dirs)
        update_last_event
        callback.call(files)
      end
    end

  end
end
