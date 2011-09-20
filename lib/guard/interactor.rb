module Guard
  class Interactor

    class LockException < Exception; end
    class UnlockException < Exception; end

    attr_reader :locked

    def initialize
      @locked = false
    end

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
                ::Guard.reload
              when 'pause', 'p'
                ::Guard.pause
              else
                ::Guard.run_all
              end
            end
          rescue LockException
            lock
          rescue UnlockException
            unlock
          end
        end
      end
    end

    def lock
      if @thread == Thread.current
        @locked = true
      else
        @thread.raise(LockException)
      end
    end

    def unlock
      if @thread == Thread.current
        @locked = false
      else
        @thread.raise(UnlockException)
      end
    end

  end
end
