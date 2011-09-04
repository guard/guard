module Guard
  class Interactor

    attr_reader :locked

    def initialize
      @locked = false
    end

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

    def lock
      @locked = true
    end

    def unlock
      @locked = false
    end

  end
end
