require "thread"
require "listen"
require "guard/options"

module Guard
  # Sets up initial variables and options
  module Setuper
    DEFAULT_OPTIONS = {
      clear: false,
      notify: true,
      debug: false,
      group: [],
      plugin: [],
      watchdir: nil,
      guardfile: nil,
      no_interactions: false,
      no_bundler_warning: false,
      show_deprecations: false,
      latency: nil,
      force_polling: false,
      wait_for_delay: nil,
      listen_on: nil
    }
    DEFAULT_GROUPS = [:default, :common]

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
    #

    # TODO: this method has too many instance variables
    # and some are mock and leak between tests,
    # so ideally there should be a guard "instance"
    # object that can be created anew between tests
    def setup(opts = {})
      reset_options(opts)
      reset_evaluator(opts)

      @queue = Queue.new
      @runner = ::Guard::Runner.new
      @watchdirs = _setup_watchdirs

      ::Guard::UI.setup(options)

      _setup_debug if options[:debug]
      @listener = _setup_listener
      _setup_signal_traps

      _load_guardfile
      @interactor = _setup_interactor
      self
    end

    attr_reader :options, :interactor

    # Used only by tests (for all I know...)
    def clear_options
      @options = nil
    end

    # Initializes the groups array with the default group(s).
    #
    # @see DEFAULT_GROUPS
    #
    def reset_groups
      @groups = DEFAULT_GROUPS.map { |name| Group.new(name) }
    end

    # Initializes the plugins array to an empty array.
    #
    # @see Guard.plugins
    #
    def reset_plugins
      @plugins = []
    end

    # Initializes the scope hash to `{ groups: [], plugins: [] }`.
    #
    # @see Guard.setup_scope
    #
    def reset_scope
      # calls Guard.scope=() to set the instance variable directly, as opposed
      # to Guard.scope()
      ::Guard.scope = { groups: [], plugins: [] }
    end

    # Used to merge CLI options with Setuper defaults
    def reset_options(new_options)
      @options = ::Guard::Options.new(new_options, DEFAULT_OPTIONS)
    end

    # TODO: code smell - too many reset_* methods
    def reset_evaluator(new_options)
      @evaluator = ::Guard::Guardfile::Evaluator.new(new_options)
    end

    def save_scope
      # This actually replaces scope from command line,
      # so scope set by 'scope' Pry command will be reset
      @saved_scope = _prepare_scope(::Guard.scope)
    end

    def restore_scope
      ::Guard.setup_scope(@saved_scope)
    end

    attr_reader :watchdirs

    # Stores the scopes defined by the user via the `--group` / `-g` option (to
    # run only a specific group) or the `--plugin` / `-P` option (to run only a
    # specific plugin).
    #
    # @see CLI#start
    # @see Dsl#scope
    #
    def setup_scope(scope = {})
      # TODO: there should be a special Scope class instead
      scope = _prepare_scope(scope)

      ::Guard.scope = {
        groups: scope[:groups].map { |item| ::Guard.add_group(item) },
        plugins: scope[:plugins].map { |item| ::Guard.plugin(item) },
      }
    end

    # Evaluates the Guardfile content. It displays an error message if no
    # Guard plugins are instantiated after the Guardfile evaluation.
    #
    # @see Guard::Guardfile::Evaluator#evaluate_guardfile
    #
    def evaluate_guardfile
      evaluator.evaluate_guardfile
      msg = "No plugins found in Guardfile, please add at least one."
      ::Guard::UI.error msg unless _pluginless_guardfile?
    end

    # Asynchronously trigger changes
    #
    # Currently supported args:
    #
    #   old style hash: {modified: ['foo'], added: ['bar'], removed: []}
    #
    #   new style signals with args: [:guard_pause, :unpaused ]
    #
    def async_queue_add(changes)
      @queue << changes

      # Putting interactor in background puts guard into foreground
      # so it can handle change notifications
      Thread.new { interactor.background }
    end

    def pending_changes?
      ! @queue.empty?
    end

    def add_builtin_plugins(guardfile)
      return unless guardfile

      pattern = _relative_pathname(guardfile).to_s
      watcher = ::Guard::Watcher.new(pattern)
      ::Guard.add_plugin(:reevaluator, watchers: [watcher], group: :common)
    end

    private

    # Sets up various debug behaviors:
    #
    # * Abort threads on exception;
    # * Set the logging level to `:debug`;
    # * Modify the system and ` methods to log themselves before being executed
    #
    # @see #_debug_command_execution
    #
    def _setup_debug
      Thread.abort_on_exception = true
      ::Guard::UI.options[:level] = :debug
      _debug_command_execution
    end

    # Initializes the listener and registers a callback for changes.
    #
    def _setup_listener
      if options[:listen_on]
        Listen.on(options[:listen_on], &_listener_callback)
      else
        listener_options = {}
        [:latency, :force_polling, :wait_for_delay].each do |option|
          listener_options[option] = options[option] if options[option]
        end
        listen_args = watchdirs + [listener_options]
        Listen.to(*listen_args, &_listener_callback)
      end
    end

    # Process the change queue, running tasks within the main Guard thread
    def _process_queue
      actions, changes = [], { modified: [], added: [], removed: [] }

      while pending_changes?
        if (item = @queue.pop).first.is_a?(Symbol)
          actions << item
        else
          item.each { |key, value| changes[key] += value }
        end
      end

      _run_actions(actions)
      runner.run_on_changes(*changes.values)
    end

    # Sets up traps to catch signals used to control Guard.
    #
    # Currently two signals are caught:
    # - `USR1` which pauses listening to changes.
    # - `USR2` which resumes listening to changes.
    # - 'INT' which is delegated to Pry if active, otherwise stops Guard.
    #
    def _setup_signal_traps
      return if defined?(JRUBY_VERSION)

      if Signal.list.keys.include?("USR1")
        Signal.trap("USR1") { async_queue_add([:guard_pause, :paused]) }
      end

      if Signal.list.keys.include?("USR2")
        Signal.trap("USR2") { async_queue_add([:guard_pause, :unpaused]) }
      end

      return unless Signal.list.keys.include?("INT")
      Signal.trap("INT") { interactor.handle_interrupt }
    end

    # Enables or disables the notifier based on user's configurations.
    #
    def _setup_notifier
      if options[:notify] && ENV["GUARD_NOTIFY"] != "false"
        ::Guard::Notifier.turn_on
      else
        ::Guard::Notifier.turn_off
      end
    end

    # Adds a command logger in debug mode. This wraps common command
    # execution functions and logs the executed command before execution.
    #
    def _debug_command_execution
      Kernel.send(:alias_method, :original_system, :system)
      Kernel.send(:define_method, :system) do |command, *args|
        ::Guard::UI.debug "Command execution: #{ command } #{ args.join(" ") }"
        Kernel.send :original_system, command, *args
      end

      Kernel.send(:alias_method, :original_backtick, :'`')
      Kernel.send(:define_method, :'`') do |command|
        ::Guard::UI.debug "Command execution: #{ command }"
        Kernel.send :original_backtick, command
      end
    end

    # TODO: Guard::Watch or Guard::Scope should provide this
    def _scoped_watchers
      watchers = []
      runner.send(:_scoped_plugins) { |guard| watchers += guard.watchers }
      watchers
    end

    # Check if any of the changes are actually watched for
    def _relevant_changes?(changes)
      files = changes.values.flatten(1)
      watchers = _scoped_watchers
      watchers.any? { |watcher| files.any? { |file| watcher.match(file) } }
    end

    def _relative_pathname(path)
      full_path = Pathname(path)
      full_path.relative_path_from(Pathname.pwd)
    rescue ArgumentError
      full_path
    end

    def _relative_pathnames(paths)
      paths.map { |path| _relative_pathname(path) }
    end

    def _run_actions(actions)
      actions.each do |action_args|
        args = action_args.dup
        namespaced_action = args.shift
        action = namespaced_action.to_s.sub(/^guard_/, "")
        if ::Guard.respond_to?(action)
          ::Guard.send(action, *args)
        else
          fail "Unknown action: #{action.inspect}"
        end
      end
    end

    def _setup_watchdirs
      dirs = Array(options[:watchdir])
      dirs.empty? ? [Dir.pwd] : dirs.map { |dir| File.expand_path dir }
    end

    def _listener_callback
      lambda do |modified, added, removed|
        relative_paths = {
          modified: _relative_pathnames(modified),
          added: _relative_pathnames(added),
          removed: _relative_pathnames(removed)
        }

        async_queue_add(relative_paths) if _relevant_changes?(relative_paths)
      end
    end

    def _reset_all
      reset_groups
      reset_plugins
      reset_scope
    end

    def _setup_interactor
      ::Guard::Interactor.new(options[:no_interactions])
    end

    def _load_guardfile
      _reset_all
      evaluate_guardfile
      setup_scope
      _setup_notifier
    end

    def _prepare_scope(scope)
      fail "Guard::setup() not called!" if options.nil?
      plugins = Array(options[:plugin])
      plugins = Array(scope[:plugins] || scope[:plugin]) if plugins.empty?

      # Convert objects to names
      plugins.map! { |p| p.respond_to?(:name) ? p.name : p }

      groups = Array(options[:group])
      groups = Array(scope[:groups] || scope[:group]) if groups.empty?

      # Convert objects to names
      groups.map! { |g| g.respond_to?(:name) ? g.name : g }

      { plugins: plugins, groups: groups }
    end

    def _pluginless_guardfile?
      # no Reevaluator means there was no Guardfile configured that could be
      # reevaluated, so we don't have a pluginless guardfile, because we don't
      # have a Guardfile to begin with...
      #
      # But, if we have a Guardfile, we'll at least have the built-in
      # Reevaluator, so the following will work:

      plugins.map(&:name) != ["reevaluator"]
    end

    def _reset_for_tests
      @options = nil
      @queue = nil
      @runner = nil
      @evaluator = nil
      @watchdirs = nil
      @watchdirs = nil
      @listener = nil
      @interactor = nil
      @scope = nil
    end
  end
end
