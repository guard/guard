module Guard
  # Commands supported by guard
  module Commander
    # Start Guard by evaluating the `Guardfile`, initializing declared Guard
    # plugins and starting the available file change listener.
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
      setup(options)
      ::Guard::UI.debug "Guard starts all plugins"
      runner.run(:start)
      listener.start

      watched = ::Guard.watchdirs.join("', '")
      ::Guard::UI.info "Guard is now watching at '#{ watched }'"

      _interactor_loop
    end

    # TODO: refactor (left to avoid breaking too many specs)
    def stop
      listener.stop
      interactor.background
      ::Guard::UI.debug "Guard stops all plugins"
      runner.run(:stop)
      ::Guard::Notifier.turn_off
      ::Guard::UI.info "Bye bye...", reset: true
    end

    # Reload Guardfile and all Guard plugins currently enabled.
    # If no scope is given, then the Guardfile will be re-evaluated,
    # which results in a stop/start, which makes the reload obsolete.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def reload(scopes = {})
      ::Guard::UI.clear(force: true)
      ::Guard::UI.action_with_scopes("Reload", scopes)

      if scopes.empty?
        evaluator.reevaluate_guardfile
      else
        runner.run(:reload, scopes)
      end
    end

    # Trigger `run_all` on all Guard plugins currently enabled.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def run_all(scopes = {})
      ::Guard::UI.clear(force: true)
      ::Guard::UI.action_with_scopes("Run", scopes)
      runner.run(:run_all, scopes)
    end

    # Pause Guard listening to file changes.
    #
    def pause(expected = nil)
      paused = listener.paused?
      states = { paused: true, unpaused: false, toggle: !paused }
      pause = states[expected || :toggle]
      fail ArgumentError, "invalid mode: #{expected.inspect}" if pause.nil?
      return if pause == paused

      listener.send(pause ? :pause : :unpause)
      UI.info "File modification listening is now #{pause.to_s.upcase}"
    end

    def show
      ::Guard::DslDescriber.new(::Guard.options).show
    end

    private

    # TODO: remove (left to avoid breaking too many specs)
    def _interactor_loop
      while interactor.foreground != :exit
        _process_queue while pending_changes?
      end
    rescue Interrupt
      stop
    end
  end
end
