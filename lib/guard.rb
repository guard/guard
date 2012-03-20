require 'thread'
require 'listen'

# Guard is the main module for all Guard related modules and classes.
# Also other Guard implementation should use this namespace.
#
module Guard

  autoload :UI,           'guard/ui'
  autoload :Dsl,          'guard/dsl'
  autoload :DslDescriber, 'guard/dsl_describer'
  autoload :Group,        'guard/group'
  autoload :Interactor,   'guard/interactor'
  autoload :Watcher,      'guard/watcher'
  autoload :Notifier,     'guard/notifier'
  autoload :Hook,         'guard/hook'

  # The Guardfile template for `guard init`
  GUARDFILE_TEMPLATE = File.expand_path('../guard/templates/Guardfile', __FILE__)
  # The location of user defined templates
  HOME_TEMPLATES = File.expand_path('~/.guard/templates')

  class << self
    attr_accessor :options, :interactor, :runner, :listener, :lock

    # Creates the initial Guardfile template when it does not
    # already exist.
    #
    # @see Guard::CLI.init
    #
    # @param [Hash] options The options for creating a Guardfile
    # @option options [Boolean] :abort_on_existence Whether to abort or not when a Guardfile already exists
    #
    def create_guardfile(options = {})
      if !File.exist?('Guardfile')
        ::Guard::UI.info "Writing new Guardfile to #{ Dir.pwd }/Guardfile"
        FileUtils.cp(GUARDFILE_TEMPLATE, 'Guardfile')
      elsif options[:abort_on_existence]
        ::Guard::UI.error "Guardfile already exists at #{ Dir.pwd }/Guardfile"
        abort
      end
    end

    # Adds the Guardfile template of a Guard implementation
    # to an existing Guardfile.
    #
    # @see Guard::CLI.init
    #
    # @param [String] guard_name the name of the Guard or template to initialize
    #
    def initialize_template(guard_name)
      guard_class = ::Guard.get_guard_class(guard_name, true)

      if guard_class
        guard_class.init(guard_name)
      elsif File.exist?(File.join(HOME_TEMPLATES, guard_name))
        content  = File.read('Guardfile')
        template = File.read(File.join(HOME_TEMPLATES, guard_name))

        File.open('Guardfile', 'wb') do |f|
          f.puts(content)
          f.puts("")
          f.puts(template)
        end

        ::Guard::UI.info "#{ guard_name } template added to Guardfile, feel free to edit it"
      else
        const_name  = guard_name.downcase.gsub('-', '')
        UI.error "Could not load 'guard/#{ guard_name.downcase }' or '~/.guard/templates/#{ guard_name.downcase }' or find class Guard::#{ const_name.capitalize }"
      end
    end

    # Adds the templates of all installed Guard implementations
    # to an existing Guardfile.
    #
    # @see Guard::CLI.init
    #
    def initialize_all_templates
      guard_gem_names.each {|g| initialize_template(g) }
    end

    # Smart accessor for retrieving a specific guard or several guards at once.
    #
    # @see Guard.groups
    #
    # @example Filter Guards by String or Symbol
    #   Guard.guards('rspec')
    #   Guard.guards(:rspec)
    #
    # @example Filter Guards by Regexp
    #   Guard.guards(/rsp.+/)
    #
    # @example Filter Guards by Hash
    #   Guard.guards({ :name => 'rspec', :group => 'backend' })
    #
    # @param [String, Symbol, Regexp, Hash] filter the filter to apply to the Guards
    # @return [Array<Guard>] the filtered Guards
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

    # Smart accessor for retrieving a specific group or several groups at once.
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

    # Initialize the groups array with the `:default` group.
    #
    # @see Guard.groups
    #
    def reset_groups
      @groups = [Group.new(:default)]
    end

    # Initialize the Guard singleton:
    #
    # - Initialize the internal Guard state.
    # - Create the interactor when necessary for user interaction.
    # - Select and initialize the file change listener.
    #
    # @option options [Boolean] clear if auto clear the UI should be done
    # @option options [Boolean] notify if system notifications should be shown
    # @option options [Boolean] verbose if verbose output should be shown
    # @option options [Array<String>] group the list of groups to start
    # @option options [String] watchdir the director to watch
    # @option options [String] guardfile the path to the Guardfile
    # @option options [Boolean] watch_all_modifications watches all file modifications if true
    #
    def setup(options = {})
      @lock       = Mutex.new
      @options    = options
      @watchdir   = (options[:watchdir] && File.expand_path(options[:watchdir])) || Dir.pwd
      @guards     = []
      self.reset_groups
      @runner     = Runner.new
      @listener   = Listen.to(@watchdir, Hash.new(options))

      if Signal.list.keys.include?('USR1')
        Signal.trap('USR1') { ::Guard.pause unless @listener.paused? }
      end

      if Signal.list.keys.include?('USR2')
        Signal.trap('USR2') { ::Guard.pause if @listener.paused? }
      end

      UI.clear if @options[:clear]
      debug_command_execution if @options[:verbose]

      Dsl.evaluate_guardfile(options)
      UI.error 'No guards found in Guardfile, please add at least one.' if ::Guard.guards.empty?
        
      runner.depraction_warning # Guard deprecation go here

      options[:notify] && ENV['GUARD_NOTIFY'] != 'false' ? Notifier.turn_on : Notifier.turn_off

      callback = lambda do |modified, added, removed|
        Dsl.reevaluate_guardfile if Watcher.match_guardfile?(modified)
        runner.run_on_changes(modified, added, removed)
        # run_on_change(modified)  if Watcher.match_files?(guards, modified)
      end
      @listener = listener.change(&callback)

      unless options[:no_interactions]
        @interactor = Interactor.fabricate
        @interactor.start if @interactor
      end

      self
    end

    # Start Guard by evaluate the `Guardfile`, initialize the declared Guards
    # and start the available file change listener.
    # Main method for Guard that is called from the CLI when guard starts.
    #
    # - Setup Guard internals
    # - Evaluate the `Guardfile`
    # - Configure Notifiers
    # - Initialize the declared Guards
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

      UI.info "Guard is now watching at '#{ @watchdir }'"

      runner.run(:start)
      # run_on_guards do |guard|
      #   run_supervised_task(guard, :start)
      # end

      listener.start
    end

    # Stop Guard listening to file changes
    #
    def stop
      interactor.stop if interactor
      listener.stop


      runner.run(:stop)
      # run_on_guards do |guard|
      #   run_supervised_task(guard, :stop)
      # end


      UI.info 'Bye bye...', :reset => true
    end

    # Reload all Guards currently enabled.
    #
    # @param [Hash] scopes an hash with a guard or a group scope
    #
    def reload(scopes)
      runner.run_with_scopes(:reload, scopes)
      # run do
      #   run_on_guards(scopes) do |guard|
      #     run_supervised_task(guard, :reload)
      #   end
      # end
    end

    # Trigger `run_all` on all Guards currently enabled.
    #
    # @param [Hash] scopes an hash with a guard or a group scope
    #
    def run_all(scopes)
      runner.run_with_scopes(:reload, scopes)
      # run do
      #   run_on_guards(scopes) do |guard|
      #     run_supervised_task(guard, :run_all)
      #   end
      # end
    end

    # Pause Guard listening to file changes.
    #
    def pause
      if listener.paused?
        UI.info 'Un-paused files modification listening', :reset => true
        listener.unpause
      else
        UI.info 'Paused files modification listening', :reset => true
        listener.pause
      end
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

    # Tries to load the Guard main class. This transforms the supplied Guard
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
          UI.error "Could not find class Guard::#{ const_name.capitalize }"
        end
      rescue LoadError => loadError
        unless fail_gracefully
          UI.error "Could not load 'guard/#{ name.downcase }' or find class Guard::#{ const_name.capitalize }"
          UI.error loadError.to_s
        end
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

  end
end
