module Guard

  # Listener implementation for Mac OS X `FSEvents`.
  #
  class Darwin < Listener

    # Initialize the Listener.
    #
    def initialize(*)
      super
      @fsevent = FSEvent.new
    end

    # Start the listener.
    #
    def start
      super
      worker.run
    end

    # Stop the listener.
    #
    def stop
      super
      worker.stop
    end

    # Check if the listener is usable on the current OS.
    #
    # @return [Boolean] whether usable or not
    #
    def self.usable?
      require 'rb-fsevent'
      if !defined?(FSEvent::VERSION) || (defined?(Gem::Version) &&
          Gem::Version.new(FSEvent::VERSION) < Gem::Version.new('0.4.0'))
        UI.info 'Please update rb-fsevent (>= 0.4.0)'
        false
      else
        true
      end
    rescue LoadError
      UI.info 'Please install rb-fsevent gem for Mac OSX FSEvents support'
      false
    end

    private

    # Get the listener worker.
    #
    def worker
      @fsevent
    end

    # Watch the given directory for file changes.
    #
    # @param [String] directory the directory to watch
    #
    def watch(directory)
      worker.watch(directory) do |modified_dirs|
        files = modified_files(modified_dirs)
        @callback.call(files) unless files.empty?
      end
    end

  end
end
