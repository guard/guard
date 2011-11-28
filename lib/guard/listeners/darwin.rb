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
      $LOAD_PATH << File.expand_path('../../../vendor/darwin', __FILE__)
      require 'rb-fsevent'
    rescue LoadError
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
