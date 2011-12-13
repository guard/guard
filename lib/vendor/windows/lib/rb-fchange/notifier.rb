module FChange
  # Notifier wraps a single instance of FChange.
  # It's possible to have more than one instance,
  # but usually unnecessary.
  #
  # @example
  #   # Create the notifier
  #   notifier = FChange::Notifier.new
  #
  #   # Run this callback whenever the file path/to/foo.txt is read
  #   notifier.watch("path/to/foo/", :all_events) do
  #     puts "foo was accessed!"
  #   end
  #
  #   # Nothing happens until you run the notifier!
  #   notifier.run
  class Notifier

    #
    INFINITE = 0xFFFFFFFF

    #
    WAIT_OBJECT_0 = 0x00000000

    # A hash from {Watcher} ids to the instances themselves.
    #
    # @private
    # @return [{Fixnum => Watcher}]
    attr_reader :watchers
    
    attr_reader :dwChangeHandles
    attr_reader :lp_dwChangeHandles

    # Creates a new {Notifier}.
    #
    # @return [Notifier] 
    def initialize
      @watchers = {}
      @dwChangeHandles = []
      @lp_dwChangeHandles = 0
    end

    # Adds a new {Watcher} to the queue.
    def add_watcher(watcher)

      @watchers[watcher.id] = watcher

      @dwChangeHandles.push watcher.id

      # Pack event handles into newly created storage area 
      # to be used for Win32 call
      @lp_dwChangeHandles = dwChangeHandles.pack("L" * dwChangeHandles.count)

    end

    # Watches a file or directory for changes,
    # calling the callback when there are.
    # This is only activated once \{#process} or \{#run} is called.
    #
    # **Note that by default, this does not recursively watch subdirectories
    # of the watched directory**.
    # To do so, use the `:recursive` flag.
    #
    # `:recursive`
    # : Recursively watch any subdirectories that are created.
    #
    # @param path [String] The path to the file or directory
    # @param flags [Array<Symbol>] Which events to watch for
    # @yield [event] A block that will be called
    #   whenever one of the specified events occur
    # @yieldparam event [Event] The Event object containing information
    #   about the event that occured
    # @return [Watcher] A Watcher set up to watch this path for these events
    # @raise [SystemCallError] if the file or directory can't be watched,
    #   e.g. if the file isn't found, read access is denied,
    #   or the flags don't contain any events
    def watch(path, *flags, &callback)
      recursive = flags.include?(:recursive)
      #:latency = 0.5
      flags = flags - [:recursive]
      if flags.empty?
        @flags = [:all_events]
      else
        @flags = flags.freeze
      end
      Watcher.new(self, path, recursive, *@flags, &callback)
    end

    # Starts the notifier watching for filesystem events.
    # Blocks until \{#stop} is called.
    #
    # @see #process
    def run
      @stop = false
      process until @stop
    end

    # Stop watching for filesystem events.
    # That is, if we're in a \{#run} loop,
    # exit out as soon as we finish handling the events.
    def stop
      @stop = true
    end

    # Blocks until there are one or more filesystem events
    # that this notifier has watchers registered for.
    # Once there are events, the appropriate callbacks are called
    # and this function returns.
    #
    # @see #run
    def process
      read_events.each {|event| event.callback!}
    end

    # Blocks until there are one or more filesystem events
    # that this notifier has watchers registered for.
    # Once there are events, returns their {Event} objects.
    #
    # @private
    def read_events

      # can return WAIT_TIMEOUT  = 0x00000102
      dwWaitStatus = Native.WaitForMultipleObjects(@dwChangeHandles.count, 
        @lp_dwChangeHandles, 0, 500)

      events = []

      # this call blocks all threads completely.
      @dwChangeHandles.each_index do |index|
        if dwWaitStatus == WAIT_OBJECT_0 + index

          ev = Event.new(@watchers[@dwChangeHandles[index]])
          events << ev
        
          r = Native.FindNextChangeNotification(@dwChangeHandles[index]) 
          if r == 0 
              raise SystemCallError.new("Failed to watch", r) 
          end
        end
      end
      events
    end

    def close
      
    end

  end
end
