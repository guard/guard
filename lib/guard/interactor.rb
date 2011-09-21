module Guard

  # The interactor reads user input and triggers
  # specific action upon them unless its locked.
  #
  # Currently the following actions are implemented:
  # - stop, quit, exit, s, q, e => Exit Guard
  # - reload, r, z => Reload Guard
  # - pause, p => Pause Guard
  # - Everything else => Run all
  #
  class Interactor

    attr_reader :locked

    # Initialize the interactor in unlocked state.
    #
    def initialize
      @locked = false
    end

    # Start the interactor in a own thread.
    #
    def start
      return if ENV["GUARD_ENV"] == 'test'

      Thread.new do
        loop do
          if (entry = $stdin.gets) && !@locked
            entry.gsub! /\n/, ''
            case entry
            when 'stop', 'quit', 'exit', 's', 'q', 'e'
              ::Guard.stop
            when 'reload', 'r', 'z'
              ::Guard.reload
            when 'pause', 'p'
              ::Guard.pause
            else
              ::Guard.run_all
            end
          end
        end
      end
    end

    # Lock the interactor.
    #
    def lock
      @locked = true
    end

    # Unlock the interactor.
    #
    def unlock
      @locked = false
    end

  end
end
