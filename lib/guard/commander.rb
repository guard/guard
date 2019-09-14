require "listen"

require "guard/notifier"
require "guard/interactor"
require "guard/runner"
require "guard/dsl_describer"

require "guard/internals/state"

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
      UI.debug "Guard starts all plugins"
      Runner.new(engine: self).run(:start)
      listener.start

      watched = state.session.watchdirs.join("', '")
      UI.info "Guard is now watching at '#{ watched }'"

      exitcode = 0
      begin
        while interactor.foreground != :exit
          queue.process while self.queue.pending?
        end
      rescue Interrupt
      rescue SystemExit => e
        exitcode = e.status
      end

      exitcode
    ensure
      stop
    end

    # Initializes the Guard singleton:
    #
    # * Initialize the internal Guard state;
    # * Create the interactor
    # * Select and initialize the file change listener.
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [Array<String>] watchdir the directories to watch
    # @option options [String] guardfile the path to the Guardfile
    #
    # @return [Guard] the Guard singleton
    def setup(cmdline_options = {})
      evaluate_guardfile

      Notifier.connect(state.session.notify_options)

      traps = Internals::Traps
      traps.handle("USR1") { async_queue_add([:guard_pause, :paused]) }
      traps.handle("USR2") { async_queue_add([:guard_pause, :unpaused]) }
      traps.handle("INT") { interactor.handle_interrupt }

      self
    end

    # Initializes the Guard singleton:
    #
    # * Initialize the internal Guard state;
    # * Create the interactor
    # * Select and initialize the file change listener.
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [Array<String>] watchdir the directories to watch
    # @option options [String] guardfile the path to the Guardfile
    #
    # @return [Guard] the Guard singleton
    def setup(cmdline_options = {})
      evaluate_guardfile

      Notifier.connect(state.session.notify_options)

      traps = Internals::Traps
      traps.handle("USR1") { async_queue_add([:guard_pause, :paused]) }
      traps.handle("USR2") { async_queue_add([:guard_pause, :unpaused]) }
      traps.handle("INT") { interactor.handle_interrupt }

      self
    end

    def stop
      listener.stop
      interactor.background
      UI.debug "Guard stops all plugins"
      Runner.new(engine: self).run(:stop)
      Notifier.disconnect
      UI.info "Bye bye...", reset: true
    end

    # Reload Guardfile and all Guard plugins currently enabled.
    # If no scope is given, then the Guardfile will be re-evaluated,
    # which results in a stop/start, which makes the reload obsolete.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def reload(scopes = {})
      UI.clear(engine: self, force: true)
      UI.action_with_scopes(engine: self, action: "Reload", scopes: scopes)
      Runner.new(engine: self).run(:reload, scopes)
    end

    # Trigger `run_all` on all Guard plugins currently enabled.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def run_all(scopes = {})
      UI.clear(engine: self, force: true)
      UI.action_with_scopes(engine: self, action: "Run", scopes: scopes)
      Runner.new(engine: self).run(:run_all, scopes)
    end

    # Pause Guard listening to file changes.
    #
    def pause(expected = nil)
      paused = listener.paused?
      states = { paused: true, unpaused: false, toggle: !paused }
      pause = states[expected || :toggle]
      fail ArgumentError, "invalid mode: #{expected.inspect}" if pause.nil?
      return if pause == paused

      listener.public_send(pause ? :pause : :start)
      UI.info "File event handling has been #{pause ? 'paused' : 'resumed'}"
    end

    def show
      DslDescriber.new.show
    end
  end
end
