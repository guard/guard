module Guard

  module Commander

    # Start Guard by evaluating the `Guardfile`, initializing declared Guard plugins
    # and starting the available file change listener.
    # Main method for Guard that is called from the CLI when Guard starts.
    #
    # - Setup Guard internals
    # - Evaluate the `Guardfile`
    # - Configure Notifiers
    # - Initialize the declared Guard plugins
    # - Start the available file change listener
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [String] watchdir the director to watch
    # @option options [String] guardfile the path to the Guardfile
    # @see CLI#start
    #
    def start(options = {})
      setup(options) unless running

      within_preserved_state do
        ::Guard::UI.debug 'Guard starts all plugins'
        runner.run(:start)
        ::Guard::UI.info "Guard is now watching at '#{ @watchdirs.join "', '" }'"
        listener.start
      end
    end

    # Stop Guard listening to file changes.
    #
    def stop
      setup unless running

      within_preserved_state do
        ::Guard::UI.debug 'Guard stops all plugins'
        runner.run(:stop)
        ::Guard::Notifier.turn_off
        ::Guard::UI.info 'Bye bye...', reset: true
        listener.stop
        @running = false
      end
    end

    # Reload Guardfile and all Guard plugins currently enabled.
    # If no scope is given, then the Guardfile will be re-evaluated,
    # which results in a stop/start, which makes the reload obsolete.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def reload(scopes = {})
      setup unless running

      within_preserved_state do
        ::Guard::UI.clear(force: true)
        ::Guard::UI.action_with_scopes('Reload', scopes)

        if scopes.empty?
          evaluator.reevaluate_guardfile
        else
          runner.run(:reload, scopes)
        end
      end
    end

    # Trigger `run_all` on all Guard plugins currently enabled.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def run_all(scopes = {})
      setup unless running

      within_preserved_state do
        ::Guard::UI.clear(force: true)
        ::Guard::UI.action_with_scopes('Run', scopes)
        runner.run(:run_all, scopes)
      end
    end

    # Pause Guard listening to file changes.
    #
    def pause
      if listener.paused?
        ::Guard::UI.info 'Un-paused files modification listening', reset: true
        listener.unpause
      else
        ::Guard::UI.info 'Paused files modification listening', reset: true
        listener.pause
      end
    end

    # Runs a block where the interactor is
    # blocked and execution is synchronized
    # to avoid state inconsistency.
    #
    # @param [Boolean] restart_interactor whether to restart the interactor or
    #   not
    # @yield the block to run
    #
    def within_preserved_state
      lock.synchronize do
        begin
          interactor.stop if interactor
          @result = yield
        rescue Interrupt
          # Bring back Pry when the block is halted with Ctrl-C
        end

        interactor.start if interactor && running
      end

      @result
    end

  end

end
