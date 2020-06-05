# frozen_string_literal: true

require "forwardable"
require "listen"

require "guard/guardfile/evaluator"
require "guard/internals/helpers"
require "guard/internals/traps"
require "guard/internals/queue"
require "guard/internals/state"

require "guard/notifier"
require "guard/interactor"
require "guard/runner"
require "guard/dsl_describer"

# Guard is the main module for all Guard related modules and classes.
# Also Guard plugins should use this namespace.
module Guard
  # Engine is the main orchestrator class.
  class Engine
    extend Forwardable
    include Internals::Helpers

    # Initialize a new Guard::Engine object.
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [Array<String>] watchdirs the directories to watch
    # @option options [String] guardfile the path to the Guardfile
    # @option options [String] inline the inline content of a Guardfile
    #
    # @return [Guard::Engine] a Guard::Engine instance
    def initialize(options = {})
      @options = options
      Thread.current[:engine] = self
    end

    def state
      @state ||= Internals::State.new(self, options)
    end

    def to_s
      "#<#{self.class}:#{object_id} @options=#{options}>"
    end
    alias_method :inspect, :to_s

    delegate %i[session scope] => :state
    delegate %i[plugins groups watchdirs] => :session
    delegate paused?: :_listener

    # @private
    def interactor=(off_or_options)
      case off_or_options
      when :off
        _interactor.enabled = false
      when Hash
        _interactor.options = options
      end
    end

    # Evaludate the Guardfile.
    #
    def setup
      _evaluate
    end

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
    # @option options [String] watchdirs the director to watch
    # @option options [String] guardfile the path to the Guardfile
    # @see CLI#start
    #
    def start
      setup

      _initialize_listener
      _initialize_signal_traps
      _initialize_notifier

      UI.debug "Guard starts all plugins"
      _runner.run(:start)

      UI.info "Guard is now watching at '#{session.watchdirs.join("', '")}'"
      _listener.start

      exitcode = 0
      begin
        loop do
          break if _interactor.foreground == :exit

          loop do
            break unless _queue.pending?

            _queue.process
          end
        end
      rescue Interrupt
      rescue SystemExit => e
        exitcode = e.status
      end

      exitcode
    ensure
      stop
    end

    def stop
      _listener&.stop
      _interactor&.background
      UI.debug "Guard stops all plugins"
      _runner&.run(:stop)
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
      UI.clear(force: true)
      UI.action_with_scopes("Reload", scope.titles(scopes))
      _runner.run(:reload, scopes)
    end

    # Trigger `run_all` on all Guard plugins currently enabled.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def run_all(scopes = {})
      UI.clear(force: true)
      UI.action_with_scopes("Run", scope.titles(scopes))
      _runner.run(:run_all, scopes)
    end

    # Pause Guard listening to file changes.
    #
    def pause(expected = nil)
      states = { paused: true, unpaused: false, toggle: !paused? }
      key = expected || :toggle

      raise ArgumentError, "invalid mode: #{expected.inspect}" unless states.key?(key)

      pause = states[key]
      return if pause == paused?

      _listener.public_send(pause ? :pause : :start)
      UI.info "File event handling has been #{pause ? 'paused' : 'resumed'}"
    end

    def show
      DslDescriber.new(self).show
    end

    # @private
    # Asynchronously trigger changes
    #
    # Currently supported args:
    #
    #   @example Old style hash:
    #     async_queue_add(modified: ['foo'], added: ['bar'], removed: [])
    #
    #   @example New style signals with args:
    #     async_queue_add([:guard_pause, :unpaused ])
    #
    def async_queue_add(changes)
      _queue << changes

      # Putting interactor in background puts guard into foreground
      # so it can handle change notifications
      Thread.new { _interactor.background }
    end

    private

    attr_reader :options

    def _restart
      stop

      @state = nil
      @_listener = nil

      start
    end

    def _runner
      @_runner ||= Runner.new(self)
    end

    def _queue
      @_queue ||= Internals::Queue.new(self, _runner)
    end

    def _listener
      @_listener ||= Listen.send(*session.listener_args, &_listener_callback)
    end

    def _evaluate
      evaluator = Guardfile::Evaluator.new(self)
      evaluator.evaluate

      UI.reset_and_clear

      if evaluator.inline?
        UI.info("Using inline Guardfile.")
      elsif evaluator.custom?
        UI.info("Using Guardfile at #{evaluator.guardfile_path}.")
      end
    rescue Guardfile::Evaluator::NoPluginsError => e
      UI.error(e.message)
    end

    def _listener_callback
      lambda do |modified, added, removed|
        relative_paths = {
          modified: _relative_pathnames(modified),
          added: _relative_pathnames(added),
          removed: _relative_pathnames(removed)
        }

        async_queue_add(relative_paths)
      end
    end

    def _initialize_listener
      ignores = session.guardfile_ignore
      _listener.ignore(ignores) unless ignores.empty?

      ignores = session.guardfile_ignore_bang
      _listener.ignore!(ignores) unless ignores.empty?
    end

    def _initialize_signal_traps
      traps = Internals::Traps
      traps.handle("USR1") { async_queue_add(%i(guard_pause paused)) }
      traps.handle("USR2") { async_queue_add(%i(guard_pause unpaused)) }
      traps.handle("INT") { _interactor.handle_interrupt }
    end

    def _interactor
      @_interactor ||= Interactor.new(self, session.interactor_name == :pry_wrapper)
    end

    def _initialize_notifier
      Notifier.connect(session.notify_options)
    end
  end
end
