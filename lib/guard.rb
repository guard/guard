require 'thread'

# Guard is the main module for all Guard related modules and classes.
# Also other Guard implementation should use this namespace.
#
module Guard

  autoload :UI,           'guard/ui'
  autoload :Dsl,          'guard/dsl'
  autoload :DslDescriber, 'guard/dsl_describer'
  autoload :Group,        'guard/group'
  autoload :Interactor,   'guard/interactor'
  autoload :Listener,     'guard/listener'
  autoload :Watcher,      'guard/watcher'
  autoload :Notifier,     'guard/notifier'
  autoload :Hook,         'guard/hook'

  # The Guardfile template for `guard init`
  GUARDFILE_TEMPLATE = File.expand_path('../guard/templates/Guardfile', __FILE__)

  class << self
    attr_accessor :options, :interactor, :listener, :lock

    # Creates the initial Guardfile template or add a Guard implementation
    # Guardfile template to an existing Guardfile.
    #
    # @see Guard::Guard.init
    #
    # @param [String] guard_name the name of the Guard to initialize
    #
    def initialize_template(guard_name = nil)
      if !File.exist?('Guardfile')
        ::Guard::UI.info "Writing new Guardfile to #{ Dir.pwd }/Guardfile"
        FileUtils.cp(GUARDFILE_TEMPLATE, 'Guardfile')
      elsif guard_name.nil?
        ::Guard::UI.error "Guardfile already exists at #{ Dir.pwd }/Guardfile"
        exit 1
      end

      if guard_name
        guard_class = ::Guard.get_guard_class(guard_name)
        guard_class.init(guard_name)
      end
    end

    # Initialize the Guard singleton.
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [String] watchdir the director to watch
    # @option options [String] guardfile the path to the Guardfile
    # @option options [Boolean] watch_all_modifications watches all file modifications if true
    #
    def setup(options = {})
      @lock = Mutex.new

      @options    = options
      @guards     = []
      self.reset_groups
      @interactor = Interactor.new unless @options[:no_interactions]
      @listener   = Listener.select_and_init(@options[:watchdir] ? File.expand_path(@options[:watchdir]) : Dir.pwd, options)

      @options[:notify] && ENV['GUARD_NOTIFY'] != 'false' ? Notifier.turn_on : Notifier.turn_off

      UI.clear if @options[:clear]

      debug_command_execution if @options[:debug]

      self
    end

    # Smart accessor for retrieving a specific guard or several guards at once.
    #
    # @param [String, Symbol] filter return the guard with the given name, or nil if not found
    # @param [Regexp] filter returns all guards matching the Regexp, or [] if no guard found
    # @param [Hash] filter returns all guards matching the given Hash.
    #   Example: `{ :name => 'rspec', :group => 'backend' }`, or [] if no guard found
    # @param [NilClass] filter returns all guards
    #
    # @see Guard.groups
    #
    def guards(filter = nil)
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

    # Smart accessor for retrieving a specific group or several groups at once.
    #
    # @param [NilClass] filter returns all groups
    # @param [String, Symbol] filter return the group with the given name, or nil if not found
    # @param [Regexp] filter returns all groups matching the Regexp, or [] if no group found
    #
    # @see Guard.guards
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

    # Initialize the groups array with the `:default` group.
    #
    # @see Guard.groups
    #
    def reset_groups
      @groups = [Group.new(:default)]
    end

    # Start Guard by evaluate the `Guardfile`, initialize the declared Guards
    # and start the available file change listener.
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

      Dsl.evaluate_guardfile(options)

      listener.on_change do |files|
        Dsl.reevaluate_guardfile        if Watcher.match_guardfile?(files)
        listener.changed_files += files if Watcher.match_files?(guards, files)
      end

      UI.info "Guard is now watching at '#{ listener.directory }'"

      run_on_guards do |guard|
        run_supervised_task(guard, :start)
      end

      interactor.start if interactor
      listener.start
    end

    # Stop Guard listening to file changes
    #
    def stop
      UI.info 'Bye bye...', :reset => true

      run_on_guards do |guard|
        run_supervised_task(guard, :stop)
      end

      listener.stop
      abort
    end

    # Reload all Guards currently enabled.
    #
    # @param [Hash] An hash with a guard or a group scope
    #
    def reload(scopes)
      run do
        run_on_guards(scopes) do |guard|
          run_supervised_task(guard, :reload)
        end
      end
    end

    # Trigger `run_all` on all Guards currently enabled.
    #
    # @param [Hash] An hash with a guard or a group scope
    #
    def run_all(scopes)
      run do
        run_on_guards(scopes) do |guard|
          run_supervised_task(guard, :run_all)
        end
      end
    end

    # Pause Guard listening to file changes.
    #
    def pause
      if listener.paused?
        UI.info 'Un-paused files modification listening', :reset => true
        listener.clear_changed_files
        listener.run
      else
        UI.info 'Paused files modification listening', :reset => true
        listener.pause
      end
    end

    # Trigger `run_on_change` on all Guards currently enabled.
    #
    def run_on_change(files)
      run do
        run_on_guards do |guard|
          run_on_change_task(files, guard)
        end
      end
    end

    # Run a block where the listener and the interactor is
    # blocked.
    #
    # @yield the block to run
    #
    def run
      UI.clear if options[:clear]

      lock.synchronize do
        begin
          interactor.stop if interactor
          yield
        rescue Interrupt
        end

        interactor.start if interactor
      end
    end

    # Loop through all groups and run the given task (as block) for each Guard.
    #
    # Stop the task run for the all Guards within a group if one Guard
    # throws `:task_has_failed`.
    #
    # @param [Hash] An hash with a guard or a group scope
    #
    def run_on_guards(scopes = {})
      if guard = scopes[:guard]
        yield(guard)
      else
        groups = scopes[:group] ? [scopes[:group]] : @groups
        groups.each do |group|
          catch :task_has_failed do
            guards(:group => group.name).each do |guard|
              yield(guard)
            end
          end
        end
      end
    end

    # Run the `:run_on_change` task. When the option `:watch_all_modifications` is set,
    # the task is split to run changed paths on {Guard::Guard#run_on_change}, whereas
    # deleted paths run on {Guard::Guard#run_on_deletion}.
    #
    # @param [Array<String>] files the list of files to pass to the task
    # @param [Guard::Guard] guard the guard to run
    # @raise [:task_has_failed] when task has failed
    #
    def run_on_change_task(files, guard)
      paths = Watcher.match_files(guard, files)
      changes = changed_paths(paths)
      deletions = deleted_paths(paths)

      unless changes.empty?
        UI.debug "#{ guard.class.name }#run_on_change with #{ changes.inspect }"
        run_supervised_task(guard, :run_on_change, changes)
      end

      unless deletions.empty?
        UI.debug "#{ guard.class.name }#run_on_deletion with #{ deletions.inspect }"
        run_supervised_task(guard, :run_on_deletion, deletions)
      end
    end

    # Detects the paths that have changed.
    #
    # Deleted paths are prefixed by an exclamation point.
    # @see Guard::Listener#modified_files
    #
    # @param [Array<String>] paths the watched paths
    # @return [Array<String>] the changed paths
    #
    def changed_paths(paths)
      paths.select { |f| !f.respond_to?(:start_with?) || !f.start_with?('!') }
    end

    # Detects the paths that have been deleted.
    #
    # Deleted paths are prefixed by an exclamation point.
    # @see Guard::Listener#modified_files
    #
    # @param [Array<String>] paths the watched paths
    # @return [Array<String>] the deleted paths
    #
    def deleted_paths(paths)
      paths.select { |f| f.respond_to?(:start_with?) && f.start_with?('!') }.map { |f| f.slice(1..-1) }
    end

    # Run a Guard task, but remove the Guard when his work leads to a system failure.
    #
    # When the Group has `:halt_on_fail` disabled, we've to catch `:task_has_failed`
    # here in order to avoid an uncaught throw error.
    #
    # @param [Guard::Guard] guard the Guard to execute
    # @param [Symbol] task the task to run
    # @param [Array] args the arguments for the task
    # @raise [:task_has_failed] when task has failed
    #
    def run_supervised_task(guard, task, *args)
      catch guard_symbol(guard) do
        guard.hook("#{ task }_begin", *args)
        result = guard.send(task, *args)
        guard.hook("#{ task }_end", result)

        result
      end

    rescue Exception => ex
      UI.error("#{ guard.class.name } failed to achieve its <#{ task.to_s }>, exception was:" +
               "\n#{ ex.class }: #{ ex.message }\n#{ ex.backtrace.join("\n") }")

      guards.delete guard
      UI.info("\n#{ guard.class.name } has just been fired")

      ex
    end

    # Get the symbol we have to catch when running a supervised task.
    # If we are within a Guard group that has the `:halt_on_fail`
    # option set, we do NOT catch it here, it will be catched at the
    # group level.
    #
    # @see .run_on_guards
    #
    # @param [Guard::Guard] guard the Guard to execute
    # @return [Symbol] the symbol to catch
    #
    def guard_symbol(guard)
      if guard.group.class == Symbol
        group = groups(guard.group)
        group.options[:halt_on_fail] ? :no_catch : :task_has_failed
      else
        :task_has_failed
      end
    end

    # Add a Guard to use.
    #
    # @param [String] name the Guard name
    # @param [Array<Watcher>] watchers the list of declared watchers
    # @param [Array<Hash>] callbacks the list of callbacks
    # @param [Hash] options the Guard options (see the given Guard documentation)
    # @return [Guard::Guard] the guard added
    #
    def add_guard(name, watchers = [], callbacks = [], options = {})
      if name.to_sym == :ego
        UI.deprecation('Guard::Ego is now part of Guard. You can remove it from your Guardfile.')
      else
        guard_class = get_guard_class(name)
        callbacks.each { |callback| Hook.add_callback(callback[:listener], guard_class, callback[:events]) }
        guard = guard_class.new(watchers, options)
        @guards << guard
        guard
      end
    end

    # Add a Guard group.
    #
    # @param [String] name the group name
    # @option options [Boolean] halt_on_fail if a task execution
    #   should be halted for all Guards in this group if one Guard throws `:task_has_failed`
    # @return [Guard::Group] the group added (or retrieved from the `@groups` variable if already present)
    #
    def add_group(name, options = {})
      group = groups(name)
      if group.nil?
        group = Group.new(name, options)
        @groups << group
      end
      group
    end

    # Tries to load the Guard main class.
    #
    # @param [String] name the name of the Guard
    # @return [Class, nil] the loaded class
    #
    def get_guard_class(name)
      name        = name.to_s
      try_require = false
      const_name  = name.downcase.gsub('-', '')
      begin
        require "guard/#{ name.downcase }" if try_require
        self.const_get(self.constants.find { |c| c.to_s.downcase == const_name })
      rescue TypeError
        unless try_require
          try_require = true
          retry
        else
          UI.error "Could not find class Guard::#{ const_name.capitalize }"
        end
      rescue LoadError => loadError
        UI.error "Could not load 'guard/#{ name.downcase }' or find class Guard::#{ const_name.capitalize }"
        UI.error loadError.to_s
      end
    end

    # Locate a path to a Guard gem.
    #
    # @param [String] name the name of the Guard without the prefix `guard-`
    # @return [String] the full path to the Guard gem
    #
    def locate_guard(name)
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        Gem::Specification.find_by_name("guard-#{ name }").full_gem_path
      else
        Gem.source_index.find_name("guard-#{ name }").last.full_gem_path
      end
    rescue
      UI.error "Could not find 'guard-#{ name }' gem path."
    end

    # Returns a list of guard Gem names installed locally.
    #
    # @return [Array<String>] a list of guard gem names
    #
    def guard_gem_names
      if Gem::Version.create(Gem::VERSION) >= Gem::Version.create('1.8.0')
        Gem::Specification.find_all.select { |x| x.name =~ /^guard-/ }
      else
        Gem.source_index.find_name(/^guard-/)
      end.map { |x| x.name.sub /^guard-/, '' }
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
