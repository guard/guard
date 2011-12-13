module FChange
  # An event caused by a change on the filesystem.
  # Each {Watcher} can fire many events,
  # which are passed to that watcher's callback.
  class Event
    # The {Watcher} that fired this event.
    #
    # @return [Watcher]
    attr_reader :watcher
    
    # Creates an event from a string of binary data.
    # Differs from {Event.consume} in that it doesn't modify the string.
    #
    # @private
    # @param watcher [Watcher] The {Watcher} that fired the event
    def initialize(watcher)
      @watcher = watcher
    end

    # Calls the callback of the watcher that fired this event,
    # passing in the event itself.
    #
    # @private
    def callback!
      @watcher.callback!(self)
    end

  end
end
