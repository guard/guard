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

  class << self
    attr_accessor :options, :guards, :groups, :interactor, :listener

    # Initialize the Guard singleton.
    #
    # @param [Hash] options the Guard options.
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] debug if debug output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [String] watchdir the director to watch
    # @option options [String] guardfile the path to the Guardfile
    #
    def setup(options = {})
      @options    = options
      @guards     = []
      @groups     = [Group.new(:default)]
      @interactor = Interactor.new
      @listener   = Listener.select_and_init(@options[:watchdir] ? File.expand_path(@options[:watchdir]) : Dir.pwd)

      @options[:notify] && ENV['GUARD_NOTIFY'] != 'false' ? Notifier.turn_on : Notifier.turn_off

      UI.clear if @options[:clear]
      debug_command_execution if @options[:debug]

      self
    end

    # Start Guard by evaluate the `Guardfile`, initialize the declared Guards
    # and start the available file change listener.
    #
    # @param [Hash] options the Guard options.
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

      execute_supervised_task_for_all_guards(:start)

      interactor.start
      listener.start
    end

    # Stop Guard listening to file changes
    #
    def stop
      UI.info 'Bye bye...', :reset => true
      listener.stop
      execute_supervised_task_for_all_guards(:stop)
      abort
    end

    # Reload all Guards currently enabled.
    #
    def reload
      run do
        execute_supervised_task_for_all_guards(:reload)
      end
    end

    # Trigger `run_all` on all Guards currently enabled.
    #
    def run_all
      run do
        execute_supervised_task_for_all_guards(:run_all)
      end
    end

    # Pause Guard listening to file changes.
    #
    def pause
      if listener.locked
        UI.info 'Un-paused files modification listening', :reset => true
        listener.clear_changed_files
        listener.unlock
      else
        UI.info 'Paused files modification listening', :reset => true
        listener.lock
      end
    end

    # Trigger `run_on_change` on all Guards currently enabled.
    #
    def run_on_change(paths)
      run do
        execute_supervised_task_for_all_guards(:run_on_change, paths)
      end
    end

    # Run a block where the listener and the interactor is
    # blocked.
    #
    # @yield the block to run
    #
    def run
      listener.lock
      interactor.lock
      UI.clear if options[:clear]
      begin
        yield
      rescue Interrupt
      end
      interactor.unlock
      listener.unlock
    end

    # Loop through all groups and execute the given task for each Guard in it,
    # but halt the task execution for the all Guards within a group if one Guard
    # throws `:task_has_failed` and the group has its `:halt_on_fail` option to `true`.
    #
    # @param [Symbol] task the task to run
    # @param [Array] files the list of files to pass to the task
    #
    def execute_supervised_task_for_all_guards(task, files = nil)
          guards.find_all { |guard| guard.group == group_hash[:name] }.each do |guard|
      groups.each do |group|
        catch group.options[:halt_on_fail] == true ? :task_has_failed : :no_catch do
            if task == :run_on_change
              paths = Watcher.match_files(guard, files)
              UI.debug "#{guard.class.name}##{task} with #{paths.inspect}"
              supervised_task(guard, task, paths)
            else
              supervised_task(guard, task)
            end
          end
        end
      end
    end

    # Let a Guard execute its task, but fire it
    # if his work leads to a system failure.
    #
    # @param [Guard::Guard] guard the Guard to execute
    # @param [Symbol] task_to_supervise the task to run
    # @param [Array] args the arguments for the task
    # @return [Boolean, Exception] the result of the Guard
    #
    def supervised_task(guard, task_to_supervise, *args)
      guard.hook("#{ task_to_supervise }_begin", *args)
      result = guard.send(task_to_supervise, *args)
      guard.hook("#{ task_to_supervise }_end", result)

      result

    rescue Exception => ex
      UI.error("#{ guard.class.name } failed to achieve its <#{ task_to_supervise.to_s }>, exception was:" +
               "\n#{ ex.class }: #{ ex.message }\n#{ ex.backtrace.join("\n") }")
      guards.delete guard
      UI.info("\n#{ guard.class.name } has just been fired")

      ex
    end

    # Add a Guard to use.
    #
    # @param [String] name the Guard name
    # @param [Array<Watcher>] watchers the list of declared watchers
    # @param [Array<Hash>] callbacks the list of callbacks
    # @param [Hash] options the Guard options
    #
    def add_guard(name, watchers = [], callbacks = [], options = {})
      if name.to_sym == :ego
        UI.deprecation('Guard::Ego is now part of Guard. You can remove it from your Guardfile.')
      else
        guard_class = get_guard_class(name)
        callbacks.each { |callback| Hook.add_callback(callback[:listener], guard_class, callback[:events]) }
        @guards << guard_class.new(watchers, options)
      end
    end

    # Add a Guard group.
    #
    # @param [String] name the group name
    # @param [Hash] options the group options
    # @option options [Boolean] halt_on_fail if a task execution
    # should be halted for all Guards in this group if one Guard throws `:task_has_failed`
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
