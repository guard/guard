module Guard

  # Listener implementation for Windows `fchange`.
  #
  class Windows < Listener

    # Initialize the Listener.
    #
    def initialize(*)
      super
      @fchange = FChange::Notifier.new
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
      $LOAD_PATH << File.expand_path('../../../vendor/windows', __FILE__)
      require 'rb-fchange'
      true
    rescue LoadError
      false
    end

    private

    # Watch the given directory for file changes.
    #
    # @param [String] directory the directory to watch
    #
    def watch(directory)
      worker.watch(directory, :all_events, :recursive) do |event|
        paths = [File.expand_path(event.watcher.path)]
        files = modified_files(paths, :all => true)
        @callback.call(files) unless files.empty?
      end
    end

    # Get the listener worker.
    #
    def worker
      @fchange
    end

  end
end
