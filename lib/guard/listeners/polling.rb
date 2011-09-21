module Guard

  # Polling listener that works cross-platform and
  # has no dependencies. This is the listener that
  # uses the most CPU processing power and has higher
  # file IO that the other implementations.
  #
  class Polling < Listener

    # Initialize the Listener.
    #
    def initialize(*)
      super
      @latency = 1.5
    end

    # Start the listener.
    #
    def start
      @stop = false
      super
      watch_change
    end

    # Stop the listener.
    #
    def stop
      super
      @stop = true
    end

    # Watch the given directory for file changes.
    #
    # @param [String] directory the directory to watch
    #
    def watch(directory)
      @existing = all_files
    end

    private

    # Watch for file system changes.
    #
    def watch_change
      until @stop
        start = Time.now.to_f
        files = modified_files([@directory], :all => true)
        @callback.call(files) unless files.empty?
        nap_time = @latency - (Time.now.to_f - start)
        sleep(nap_time) if nap_time > 0
      end
    end

  end
end
