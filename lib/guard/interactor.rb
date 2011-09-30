module Guard

  # The interactor reads user input and triggers
  # specific action upon them unless its locked.
  #
  # Currently the following actions are implemented:
  #
  # - stop, quit, exit, s, q, e => Exit Guard
  # - reload, r, z => Reload Guard
  # - pause, p => Pause Guard
  # - Everything else => Run all
  #
  class Interactor

    class LockException < Exception; end
    class UnlockException < Exception; end

    attr_reader :locked

    # Initialize the interactor in unlocked state.
    #
    def initialize
      @locked = false
    end

    # Start the interactor in its own thread.
    #
    def start
      return if ENV["GUARD_ENV"] == 'test'

      @thread = Thread.new do
        loop do
          begin
            if !@locked && (entry = $stdin.gets)
              entry.gsub! /\n/, ''
              case entry
                when 'stop', 'quit', 'exit', 's', 'q', 'e'
                  ::Guard.stop
                when 'reload', 'r', 'z'
                  ::Guard::Dsl.reevaluate_guardfile
                  ::Guard.reload
                when 'pause', 'p'
                  ::Guard.pause
                else
                  ::Guard.run_all
              end
            end
            sleep 0.1
          rescue LockException
            lock
          rescue UnlockException
            unlock
          end
        end
      end
    end

    # Lock the interactor.
    #
    def lock
      if !@thread || @thread == Thread.current
        @locked = true
      else
        @thread.raise(LockException)
      end
    end

    # Unlock the interactor.
    #
    def unlock
      if !@thread || @thread == Thread.current
        @locked = false
      else
        @thread.raise(UnlockException)
      end
    end

  end
end
