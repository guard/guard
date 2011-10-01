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

    # Start the interactor in its own thread.
    #
    def start
      return if ENV["GUARD_ENV"] == 'test'

      @thread = Thread.new do
        while entry = $stdin.gets.chomp
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
      end
    end
  end
end
