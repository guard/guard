require 'thread'
require 'listen'

# Guard is the main module for all Guard related modules and classes.
# Also Guard plugins should use this namespace.
#
module Guard

  require 'guard/dsl'
  require 'guard/guardfile'
  require 'guard/group'
  require 'guard/interactor'
  require 'guard/notifier'
  require 'guard/runner'
  require 'guard/ui'
  require 'guard/watcher'

  # The Guardfile template for `guard init`
  GUARDFILE_TEMPLATE = File.expand_path('../guard/templates/Guardfile', __FILE__)

  # The location of user defined templates
  HOME_TEMPLATES = File.expand_path('~/.guard/templates')

  class << self
    attr_accessor :options, :interactor, :runner, :listener, :lock

    # Initialize the Guard singleton:
    #
    # - Initialize the internal Guard state.
    # - Create the interactor when necessary for user interaction.
    # - Select and initialize the file change listener.
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [String] watchdir the director to watch
    # @option options [String] guardfile the path to the Guardfile
    # @deprecated @option options [Boolean] watch_all_modifications watches all file modifications if true
    # @deprecated @option options [Boolean] no_vendor ignore vendored dependencies
    #
    def setup(options = {})
      @lock       = Mutex.new
      @options    = options
      @watchdir   = (options[:watchdir] && File.expand_path(options[:watchdir])) || Dir.pwd
      @runner     = ::Guard::Runner.new
      @allow_stop = Listen::Turnstile.new

      ::Guard::UI.clear(:force => true)
      deprecated_options_warning

      setup_groups
      setup_guards
      setup_listener
      setup_signal_traps

      debug_command_execution if @options[:debug]

      ::Guard::Dsl.evaluate_guardfile(options)
      ::Guard::UI.error 'No guards found in Guardfile, please add at least one.' if @guards.empty?

      runner.deprecation_warning if @options[:show_deprecations]

      setup_notifier
      setup_interactor

      self
    end

    # Initialize the groups array with the `:default` group.
    #
    # @see Guard.groups
    #
    def setup_groups
      @groups = [Group.new(:default)]
    end

    # Initialize the guards array to an empty array.
    #
    # @see Guard.guards
    #
    def setup_guards
      @guards = []
    end

    # Sets up traps to catch signals used to control Guard.
    #
    # Currently two signals are caught:
    # - `USR1` which pauses listening to changes.
    # - `USR2` which resumes listening to changes.
    #
    def setup_signal_traps
      unless defined?(JRUBY_VERSION)
        if Signal.list.keys.include?('USR1')
          Signal.trap('USR1') { ::Guard.pause unless @listener.paused? }
        end

        if Signal.list.keys.include?('USR2')
          Signal.trap('USR2') { ::Guard.pause if @listener.paused? }
        end
      end
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

    # Enables or disables the notifier based on user's configurations.
    #
    def setup_notifier
      options[:notify] && ENV['GUARD_NOTIFY'] != 'false' ? ::Guard::Notifier.turn_on : ::Guard::Notifier.turn_off
    end

    # Initializes the interactor unless the user has specified not to.
    #
    def setup_interactor
      unless options[:no_interactions]
        @interactor = ::Guard::Interactor.new
      end
    end

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
    #
    def start(options = {})
      setup(options)
      ::Guard::UI.info "Guard is now watching at '#{ @watchdir }'"

      within_preserved_state do
        runner.run(:start)
      end

      listener.start(false)

      @allow_stop.wait if @allow_stop
    end

    # Stop Guard listening to file changes
    #
    def stop
      listener.stop
      interactor.stop if interactor
      runner.run(:stop)
      ::Guard::UI.info 'Bye bye...', :reset => true

      @allow_stop.signal if @allow_stop
    end

    # Reload Guardfile and all Guard plugins currently enabled.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def reload(scopes = {})
      within_preserved_state do
        ::Guard::UI.clear(:force => true)
        ::Guard::UI.action_with_scopes('Reload', scopes)
        ::Guard::Dsl.reevaluate_guardfile if scopes.empty?
        runner.run(:reload, scopes)
      end
    end

    # Trigger `run_all` on all Guard plugins currently enabled.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def run_all(scopes = {})
      within_preserved_state do
        ::Guard::UI.clear(:force => true)
        ::Guard::UI.action_with_scopes('Run', scopes)
        runner.run(:run_all, scopes)
      end
    end

    # Pause Guard listening to file changes.
    #
    def pause
      if listener.paused?
        ::Guard::UI.info 'Un-paused files modification listening', :reset => true
        listener.unpause
      else
        ::Guard::UI.info 'Paused files modification listening', :reset => true
        listener.pause
      end
    end

    # Smart accessor for retrieving a specific Guard plugin or several Guard plugins at once.
    #
    # @see Guard.groups
    #
    # @example Filter Guard plugins by String or Symbol
    #   Guard.guards('rspec')
    #   Guard.guards(:rspec)
    #
    # @example Filter Guard plugins by Regexp
    #   Guard.guards(/rsp.+/)
    #
    # @example Filter Guard plugins by Hash
    #   Guard.guards({ :name => 'rspec', :group => 'backend' })
    #
    # @param [String, Symbol, Regexp, Hash] filter the filter to apply to the Guard plugins
    # @return [Array<Guard>] the filtered Guard plugins
    #
    def guards(filter = nil)
      @guards ||= []

      case filter
      when String, Symbol
        @guards.find { |guard| guard.class.to_s.downcase.sub('guard::', '') == filter.to_s.downcase.gsub('-', '') }
      when Regexp
        @guards.find_all { |guard| guard.class.to_s.downcase.sub('guard::', '') =~ filter }
      when Hash
        filter.inject(@guards) do |matches, (k, v)|
          if k.to_sym == :name
            matches.find_all { |guard| guard.class.to_s.downcase.sub('guard::', '') == v.to_s.downcase.gsub('-', '') }
          else
            matches.find_all { |guard| guard.send(k).to_sym == v.to_sym }
          end
        end
      else
        @guards
      end
    end

    # Smart accessor for retrieving a specific plugin group or several plugin groups at once.
    #
    # @see Guard.guards
    #
    # @example Filter groups by String or Symbol
    #   Guard.groups('backend')
    #   Guard.groups(:backend)
    #
    # @example Filter groups by Regexp
    #   Guard.groups(/(back|front)end/)
    #
    # @param [String, Symbol, Regexp] filter the filter to apply to the Groups
    # @return [Array<Group>] the filtered groups
    #
    def groups(filter = nil)
      case filter
      when String, Symbol
        @groups.find { |group| group.name == filter.to_sym }
      when Regexp
        @groups.find_all { |group| group.name.to_s =~ filter }
      else
        @groups
      end
    end

    # Add a Guard plugin to use.
    #
    # @param [String] name the Guard name
    # @param [Array<Watcher>] watchers the list of declared watchers
    # @param [Array<Hash>] callbacks the list of callbacks
    # @param [Hash] options the plugin options (see the given Guard documentation)
    # @return [Guard::Guard] the added Guard plugin
    #
    def add_guard(name, watchers = [], callbacks = [], options = {})
      if name.to_sym == :ego
        ::Guard::UI.deprecation('Guard::Ego is now part of Guard. You can remove it from your Guardfile.')
      else
        guard_class = get_guard_class(name)
        callbacks.each { |callback| Hook.add_callback(callback[:listener], guard_class, callback[:events]) }
        guard = guard_class.new(watchers, options)
        @guards << guard
        guard
      end
    end

    # Add a Guard plugin group.
    #
    # @param [String] name the group name
    # @option options [Boolean] halt_on_fail if a task execution
    #   should be halted for all Guard plugins in this group if one Guard throws `:task_has_failed`
    # @return [Guard::Group] the group added (or retrieved from the `@groups` variable if already present)
    #
    def add_group(name, options = {})
      group = groups(name)
      if group.nil?
        group = ::Guard::Group.new(name, options)
        @groups << group
      end
      group
    end

    # Runs a block where the interactor is
    # blocked and execution is synchronized
    # to avoid state inconsistency.
    #
    # @yield the block to run
    #
    def within_preserved_state
      lock.synchronize do
        begin
          interactor.stop if interactor
          @result = yield
        rescue Interrupt
        end

        interactor.start if interactor
      end
      @result
    end

    # Tries to load the Guard plugin main class. This transforms the supplied Guard plugin
    # name into a class name:
    #
    # * `guardname` will become `Guard::Guardname`
    # * `dashed-guard-name` will become `Guard::DashedGuardName`
    # * `underscore_guard_name` will become `Guard::UnderscoreGuardName`
    #
    # When no class is found with the strict case sensitive rules, another
    # try is made to locate the class without matching case:
    #
    # * `rspec` will find a class `Guard::RSpec`
    #
    # @param [String] name the name of the Guard
    # @param [Boolean] fail_gracefully whether error messages should not be printed
    # @return [Class, nil] the loaded class
    #
    def get_guard_class(name, fail_gracefully=false)
      name        = name.to_s
      try_require = false
      const_name  = name.gsub(/\/(.?)/) { "::#{ $1.upcase }" }.gsub(/(?:^|[_-])(.)/) { $1.upcase }
      begin
        require "guard/#{ name.downcase }" if try_require
        self.const_get(self.constants.find { |c| c.to_s == const_name } || self.constants.find { |c| c.to_s.downcase == const_name.downcase })
      rescue TypeError
        unless try_require
          try_require = true
          retry
        else
          ::Guard::UI.error "Could not find class Guard::#{ const_name.capitalize }"
        end
      rescue LoadError => loadError
        unless fail_gracefully
          ::Guard::UI.error "Could not load 'guard/#{ name.downcase }' or find class Guard::#{ const_name.capitalize }"
          ::Guard::UI.error loadError.to_s
        end
      end
    end

    # Locate a path to a Guard plugin gem.
    #
    # @param [String] name the name of the Guard plugin without the prefix `guard-`
    # @return [String] the full path to the Guard gem
    #
    def locate_guard(name)
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        Gem::Specification.find_by_name("guard-#{ name }").full_gem_path
      else
        Gem.source_index.find_name("guard-#{ name }").last.full_gem_path
      end
    rescue
      ::Guard::UI.error "Could not find 'guard-#{ name }' gem path."
    end

    # Returns a list of Guard plugin Gem names installed locally.
    #
    # @return [Array<String>] a list of Guard plugin gem names
    #
    def guard_gem_names
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        Gem::Specification.find_all.select { |x| x.name =~ /^guard-/ }
      else
        Gem.source_index.find_name(/^guard-/)
      end.map { |x| x.name.sub(/^guard-/, '') }
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

    # Deprecation message for the `watch_all_modifications` start option
    WATCH_ALL_MODIFICATIONS_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard v1.1 the 'watch_all_modifications' option is removed and is now always on.
    EOS

    # Deprecation message for the `no_vendor` start option
    NO_VENDOR_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard v1.1 the 'no_vendor' option is removed because the monitoring
      gems are now part of a new gem called Listen. (https://github.com/guard/listen)

      You can specify a custom version of any monitoring gem directly in your Gemfile
      if you want to overwrite Listen's default monitoring gems.
    EOS

    # Displays a warning for each deprecated options used.
    #
    def deprecated_options_warning
      ::Guard::UI.deprecation(WATCH_ALL_MODIFICATIONS_DEPRECATION) if options[:watch_all_modifications]
      ::Guard::UI.deprecation(NO_VENDOR_DEPRECATION) if options[:no_vendor]
    end

  end
end
