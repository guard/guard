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

    # @private
    ERROR_NO_PLUGINS = "No Guard plugins found in Guardfile,"\
      " please add at least one."

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

    def evaluator
      @evaluator ||= Guardfile::Evaluator.new(options)
    end

    def to_s
      "#<#{self.class}:#{object_id} @options=#{options}>"
    end
    alias_method :inspect, :to_s

    delegate %i[session] => :state
    delegate %i[plugins groups watchdirs] => :session
    delegate paused?: :_listener

    # Evaluate the Guardfile and instantiate internals.
    #
    def setup
      _instantiate

      UI.reset_and_clear

      if evaluator.inline?
        UI.info("Using inline Guardfile.")
      elsif evaluator.custom?
        UI.info("Using Guardfile at #{evaluator.guardfile_path}.")
      end

      self
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
    def reload(*entries)
      entries.flatten!
      UI.clear(force: true)
      UI.action_with_scopes("Reload", session.scope_titles(entries))
      _runner.run(:reload, entries)
    end

    # Trigger `run_all` on all Guard plugins currently enabled.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def run_all(*entries)
      entries.flatten!
      UI.clear(force: true)
      UI.action_with_scopes("Run", session.scope_titles(entries))
      _runner.run(:run_all, entries)
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
      @_runner ||= Runner.new(session)
    end

    def _queue
      @_queue ||= Internals::Queue.new(self, _runner)
    end

    def _listener
      @_listener ||= Listen.send(*session.listener_args, &_listener_callback)
    end

    # Instantiate Engine internals based on the `Guard::Guardfile::Result` populated from the `Guardfile` evaluation.
    #
    # @example Programmatically evaluate a Guardfile
    #   engine = Guard::Engine.new.setup
    #
    # @example Programmatically evaluate a Guardfile with a custom Guardfile
    # path
    #
    #   options = { guardfile: '/Users/guardfile/MyAwesomeGuardfile' }
    #   engine = Guard::Engine.new(options).setup
    #
    # @example Programmatically evaluate a Guardfile with an inline Guardfile
    #
    #   options = { inline: 'guard :rspec' }
    #   engine = Guard::Engine.new(options).setup
    #
    def _instantiate
      guardfile_result = evaluator.evaluate
      guardfile_result_plugins = guardfile_result.plugins

      UI.error(ERROR_NO_PLUGINS) if guardfile_result_plugins.empty?

      session.guardfile_notification = guardfile_result.notification
      session.guardfile_ignore = guardfile_result.ignore
      session.guardfile_ignore_bang = guardfile_result.ignore_bang
      session.guardfile_scopes = guardfile_result.scopes
      session.watchdirs = guardfile_result.directories
      session.clearing(guardfile_result.clearing)
      _instantiate_logger(guardfile_result.logger.dup)
      _instantiate_interactor(guardfile_result.interactor)

      _instantiate_groups(guardfile_result.groups)
      _instantiate_plugins(guardfile_result_plugins)
    end

    def _instantiate_interactor(interactor_options)
      case interactor_options
      when :off
        _interactor.interactive = false
      when Hash
        _interactor.options = interactor_options
      end
    end

    def _instantiate_logger(logger_options)
      if logger_options.key?(:level)
        UI.level = logger_options.delete(:level)
      end

      if logger_options.key?(:template)
        UI.template = logger_options.delete(:template)
      end

      UI.options.merge!(logger_options)
    end

    def _instantiate_groups(groups_hash)
      groups_hash.each do |name, options|
        groups.add(name, options)
      end
    end

    def _instantiate_plugins(plugins_array)
      plugins_array.each do |name, options|
        options[:group] = groups.find(options[:group])
        plugins.add(name, options)
      end
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
