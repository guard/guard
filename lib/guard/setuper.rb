module Guard

  module Setuper

    # Initializes the Guard singleton:
    #
    # * Initialize the internal Guard state;
    # * Create the interactor when necessary for user interaction;
    # * Select and initialize the file change listener.
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [String] watchdir the director to watch
    # @option options [String] guardfile the path to the Guardfile
    # @option options [Boolean] watch_all_modifications **[deprecated]** watches all file modifications if true
    # @option options [Boolean] no_vendor **[deprecated]** ignore vendored dependencies
    #
    # @return [Guard] the Guard singleton
    #
    def setup(options = {})
      @running   = true
      @lock      = Mutex.new
      @options   = options.dup
      @watchdir  = (options[:watchdir] && File.expand_path(options[:watchdir])) || Dir.pwd
      @evaluator = ::Guard::Guardfile::Evaluator.new(options)
      @runner    = ::Guard::Runner.new
      @scope     = { :plugins => [], :groups => [] }

      Dir.chdir(@watchdir)
      ::Guard::UI.clear(:force => true)
      setup_debug if options[:debug]

      setup_listener
      setup_signal_traps
      reset_groups
      reset_guards
      setup_scopes
      evaluate_guardfile

      ::Guard::Deprecator.deprecated_options_warning(options)
      ::Guard::Deprecator.deprecated_plugin_methods_warning

      setup_notifier
      setup_interactor

      self
    end

    # Evaluates the Guardfile content. It displays an error message if no
    # Guard plugins are instantiated after the Guardfile evaluation.
    #
    # @see Guard::Guardfile::Evaluator#evaluate_guardfile
    #
    def evaluate_guardfile
      evaluator.evaluate_guardfile
      ::Guard::UI.error 'No guards found in Guardfile, please add at least one.' if guards.empty?
    end

    # Sets up various debug behaviors:
    #
    # * Abort threads on exception;
    # * Set the logging level to `:debug`;
    # * Modify the system and ` methods to log themselves before being executed
    #
    # @see #debug_command_execution
    #
    def setup_debug
      Thread.abort_on_exception = true
      ::Guard::UI.options[:level] = :debug
      debug_command_execution
    end

    # Initializes the listener and registers a callback for changes.
    #
    def setup_listener
      listener_callback = lambda do |modified, added, removed|
        ::Guard::Dsl.reevaluate_guardfile if ::Guard::Watcher.match_guardfile?(modified)

        ::Guard.within_preserved_state do
          runner.run_on_changes(modified, added, removed)
        end
      end

      listener_options = { :relative_paths => true }
      %w[latency force_polling].each do |option|
        listener_options[option.to_sym] = options[option] if options.key?(option)
      end

      @listener = Listen.to(@watchdir, listener_options).change(&listener_callback)
    end

    # Sets up traps to catch signals used to control Guard.
    #
    # Currently two signals are caught:
    # - `USR1` which pauses listening to changes.
    # - `USR2` which resumes listening to changes.
    # - 'INT' which is delegated to Pry if active, otherwise stops Guard.
    #
    def setup_signal_traps
      unless defined?(JRUBY_VERSION)
        if Signal.list.keys.include?('USR1')
          Signal.trap('USR1') { ::Guard.pause unless listener.paused? }
        end

        if Signal.list.keys.include?('USR2')
          Signal.trap('USR2') { ::Guard.pause if listener.paused? }
        end

        if Signal.list.keys.include?('INT')
          Signal.trap('INT') do
            if interactor
              interactor.thread.raise(Interrupt)
            else
              ::Guard.stop
            end
          end
        end
      end
    end

    # Stores the scopes defined by the user via the `--group` / `-g` option (to run
    # only a specific group) or the `--plugin` / `-P` option (to run only a
    # specific plugin).
    #
    # @see CLI#start
    #
    def setup_scopes
      scope[:groups]  = options[:group].map { |g| ::Guard.groups(g) } if options[:group]
      scope[:plugins] = options[:plugin].map { |p| ::Guard.guards(p) } if options[:plugin]
    end

    # Enables or disables the notifier based on user's configurations.
    #
    def setup_notifier
      if options[:notify] && ENV['GUARD_NOTIFY'] != 'false'
        ::Guard::Notifier.turn_on
      else
        ::Guard::Notifier.turn_off
      end
    end

    # Initializes the interactor unless the user has specified not to.
    #
    def setup_interactor
      unless options[:no_interactions] || !::Guard::Interactor.enabled
        @interactor = ::Guard::Interactor.new
      end
    end

    # Initializes the groups array with the default group(s).
    #
    # @see #default_groups
    #
    def reset_groups
      @groups = default_groups
    end

    # Initializes the guards array to an empty array.
    #
    # @see Guard.guards
    #
    def reset_guards
      @guards = []
    end

    private

    # Returns an array of the default group(s) when Guard starts or when
    # `Guard.reset` is called.
    #
    # @see #reset_groups
    #
    # @return [Array<Guard::Group>] the default groups
    #
    def default_groups
      [Group.new(:default)]
    end

    # Adds a command logger in debug mode. This wraps common command
    # execution functions and logs the executed command before execution.
    #
    def debug_command_execution
      Kernel.send(:alias_method, :original_system, :system)
      Kernel.send(:define_method, :system) do |command, *args|
        ::Guard::UI.debug "Command execution: #{ command } #{ args.join(' ') }"
        original_system command, *args
      end

      Kernel.send(:alias_method, :original_backtick, :'`')
      Kernel.send(:define_method, :'`') do |command|
        ::Guard::UI.debug "Command execution: #{ command }"
        original_backtick command
      end
    end

  end
end
