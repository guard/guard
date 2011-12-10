require 'pathname'

module FChange
  # Watchers monitor a single path for changes,
  # specified by {FChange::Notifier#watch event flags}.
  # A watcher is usually created via \{Notifier#watch}.
  #
  # One {Notifier} may have many {Watcher}s.
  # The Notifier actually takes care of the checking for events,
  # via \{Notifier#run #run} or \{Notifier#process #process}.
  # The main purpose of having Watcher objects
  # is to be able to disable them using \{#close}.
  class Watcher
    # The {Notifier} that this Watcher belongs to.
    #
    # @return [Notifier]
    attr_reader :notifier

    # The path that this Watcher is watching.
    #
    # @return [String]
    attr_reader :path

    # The {FChange::Notifier#watch flags}
    # specifying the events that this Watcher is watching for,
    # and potentially some options as well.
    #
    # @return [Array<Symbol>]
    attr_reader :flags
    
    # The id for this Watcher.
    # Used to retrieve this Watcher from {Notifier#watchers}.
    #
    # @private
    # @return [Fixnum]
    attr_reader :id

    #
    # @private
    # @return [Boolean]
    attr_reader :recursive

    # Calls this Watcher's callback with the given {Event}.
    #
    # @private
    # @param event [Event]
    def callback!(event)
      @callback[event]
    end

    # Disables this Watcher, so that it doesn't fire any more events.
    #
    # @raise [SystemCallError] if the watch fails to be disabled for some reason
    def close
      r = Native.FindCloseChangeNotification(@id)
      #@notifier.remove_watcher(self)
      return if r == 0
      raise SystemCallError.new("Failed to stop watching #{@path.inspect}", r)
    end

    # see http://msdn.microsoft.com/en-us/library/aa365247(v=vs.85).aspx
    def normalize_path(path)
      if(path.size > 256)
        path = "\\\\?\\" + Pathname.new(path).realpath.to_s
      end
#      require 'rchardet'
#      require 'iconv'
#      cd = CharDet.detect(path)
#      encoding = cd['encoding']
#      converter = Iconv.new("UTF-16LE", encoding)
#      converter.iconv(path)
      # path.encode!("UTF-16LE")
    end

    # Creates a new {Watcher}.
    #
    # @private
    # @see Notifier#watch
    def initialize(notifier, path, recursive, *flags, &callback)
      @notifier = notifier
      @callback = callback || proc {}
      @path = path
      @flags = flags
      @recursive = recursive ? 1 : 0

      @id = Native.FindFirstChangeNotificationA(path, @recursive,
        Native::Flags.to_mask(flags));
#      @id = Native.FindFirstChangeNotificationW(normalize_path(path), @recursive,
#        Native::Flags.to_mask(flags));
 
      unless @id < 0
        @notifier.add_watcher(self)
        return
      end

      raise SystemCallError.new("Failed to watch #{path.inspect}", @id)
    end
  end
end
