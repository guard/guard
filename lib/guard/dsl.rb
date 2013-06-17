module Guard

  # The DSL class provides the methods that are used in each `Guardfile` to describe
  # the behaviour of Guard.
  #
  # The main keywords of the DSL are `guard` and `watch`. These are necessary to define
  # the used Guard plugins and the file changes they are watching.
  #
  # You can optionally group the Guard plugins with the `group` keyword and ignore and filter certain paths
  # with the `ignore` and `filter` keywords.
  #
  # You can set your preferred system notification library with `notification` and pass
  # some optional configuration options for the library. If you don't configure a library,
  # Guard will automatically pick one with default options (if you don't want notifications,
  # specify `:off` as library). @see ::Guard::Notifier for more information about the supported libraries.
  #
  # A more advanced DSL use is the `callback` keyword that allows you to execute arbitrary
  # code before or after any of the `start`, `stop`, `reload`, `run_all`, `run_on_changes`,
  # `run_on_additions`, `run_on_modifications` and `run_on_removals` Guard plugins method.
  # You can even insert more hooks inside these methods.
  # Please [checkout the Wiki page](https://github.com/guard/guard/wiki/Hooks-and-callbacks) for more details.
  #
  # The DSL will also evaluate normal Ruby code.
  #
  # There are two possible locations for the `Guardfile`:
  # - The `Guardfile` in the current directory where Guard has been started
  # - The `.Guardfile` in your home directory.
  #
  # In addition, if a user configuration `.guard.rb` in your home directory is found, it will
  # be appended to the current project `Guardfile`.
  #
  # @see https://github.com/guard/guard/wiki/Guardfile-examples
  #
  class Dsl

    require 'guard'
    require 'guard/dsl'
    require 'guard/interactor'
    require 'guard/notifier'
    require 'guard/ui'
    require 'guard/watcher'

    # Deprecation message for the `ignore_paths` method
    IGNORE_PATHS_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard v1.1 the use of the 'ignore_paths' Guardfile DSL method is deprecated.

      Please replace that method with the better 'ignore' or/and 'filter' methods.
      Documentation on the README: https://github.com/guard/guard#ignore
    EOS

    # Deprecation message for the `interactor` method
    INTERACTOR_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard v1.4 the use of the 'interactor' Guardfile DSL method is only used to
      disable or pass options to the Pry interactor. All other usages are deprecated.
    EOS

    class << self

      attr_accessor :options

      # Evaluate the DSL methods in the `Guardfile`.
      #
      # @option options [Array<Symbol,String>] groups the groups to evaluate
      # @option options [String] guardfile the path to a valid Guardfile
      # @option options [String] guardfile_contents a string representing the content of a valid Guardfile
      # @raise [ArgumentError] when options are not a Hash
      #
      def evaluate_guardfile(options = {})
        raise ArgumentError.new('No option hash passed to evaluate_guardfile!') unless options.is_a?(Hash)

        self.options = options.dup

        fetch_guardfile_contents
        instance_eval_guardfile(guardfile_contents_with_user_config)
      end

      # Re-evaluate the `Guardfile` to update the current Guard configuration.
      #
      def reevaluate_guardfile
        before_reevaluate_guardfile
        ::Guard::Dsl.evaluate_guardfile(options)
        after_reevaluate_guardfile
      end

      # Stop Guard and clear internal state
      # before the Guardfile will be re-evaluated.
      #
      def before_reevaluate_guardfile
        ::Guard.runner.run(:stop)
        ::Guard.guards.clear
        ::Guard.setup_groups
        ::Guard::Notifier.clear_notifications

        options.delete(:guardfile_contents)
      end

      # Start Guard and notification and show a message
      # after the Guardfile has been re-evaluated.
      #
      def after_reevaluate_guardfile
        ::Guard::Notifier.turn_on if ::Guard::Notifier.enabled?

        if ::Guard.guards.empty?
          ::Guard::Notifier.notify('No guards found in Guardfile, please add at least one.', :title => 'Guard re-evaluate', :image => :failed)
        else
          msg = 'Guardfile has been re-evaluated.'
          ::Guard::UI.info(msg)
          ::Guard::Notifier.notify(msg, :title => 'Guard re-evaluate')

          ::Guard.runner.run(:start)
        end
      end

      # Evaluate the content of the `Guardfile`.
      #
      # @param [String] contents the content to evaluate.
      #
      def instance_eval_guardfile(contents)
        new.instance_eval(contents, options[:guardfile_path], 1)
      rescue
        ::Guard::UI.error "Invalid Guardfile, original error is:\n#{ $! }"
      end

      # Test if the current `Guardfile` contains a specific Guard plugin.
      #
      # @param [String] guard_name the name of the Guard
      # @return [Boolean] whether the Guard has been declared
      #
      def guardfile_include?(guard_name)
        guardfile_contents.match(/^guard\s*\(?\s*['":]#{ guard_name }['"]?/)
      end

      # Read the current `Guardfile` content.
      #
      # @param [String] guardfile_path the path to the Guardfile
      #
      def read_guardfile(guardfile_path)
        options[:guardfile_path]     = guardfile_path
        options[:guardfile_contents] = File.read(guardfile_path)
      rescue
        ::Guard::UI.error("Error reading file #{ guardfile_path }")
        exit 1
      end

      # Get the content to evaluate and stores it into
      # the options as `:guardfile_contents`.
      #
      def fetch_guardfile_contents
        if options[:guardfile_contents]
          ::Guard::UI.info 'Using inline Guardfile.'
          options[:guardfile_path] = 'Inline Guardfile'

        elsif options[:guardfile]
          if File.exist?(options[:guardfile])
            read_guardfile(options[:guardfile])
            ::Guard::UI.info "Using Guardfile at #{ options[:guardfile] }."
          else
            ::Guard::UI.error "No Guardfile exists at #{ options[:guardfile] }."
            exit 1
          end

        else
          if File.exist?(guardfile_default_path)
            read_guardfile(guardfile_default_path)
          else
            ::Guard::UI.error 'No Guardfile found, please create one with `guard init`.'
            exit 1
          end
        end

        unless guardfile_contents_usable?
          ::Guard::UI.error 'No Guard plugins found in Guardfile, please add at least one.'
        end
      end

      # Get the content of the `Guardfile`.
      #
      # @return [String] the Guardfile content
      #
      def guardfile_contents
        options ? options[:guardfile_contents] : ''
      end

      # Get the content of the `Guardfile` and the global
      # user configuration file.
      #
      # @see #user_config_path
      #
      # @return [String] the Guardfile content
      #
      def guardfile_contents_with_user_config
        config = File.read(user_config_path) if File.exist?(user_config_path)
        [guardfile_contents, config].join("\n")
      end

      # Get the file path to the project `Guardfile`.
      #
      # @return [String] the path to the Guardfile
      #
      def guardfile_path
        options ? options[:guardfile_path] : ''
      end

      # Tests if the current `Guardfile` content is usable.
      #
      # @return [Boolean] if the Guardfile is usable
      #
      def guardfile_contents_usable?
        guardfile_contents && guardfile_contents.size >= 'guard :a'.size # Smallest Guard definition
      end

      # Gets the default path of the `Guardfile`. This returns the `Guardfile`
      # from the current directory when existing, or the global `.Guardfile`
      # at the home directory.
      #
      # @return [String] the path to the Guardfile
      #
      def guardfile_default_path
        File.exist?(local_guardfile_path) ? local_guardfile_path : home_guardfile_path
      end

      private

      # The path to the `Guardfile` that is located at
      # the directory, where Guard has been started from.
      #
      # @return [String] the path to the local Guardfile
      #
      def local_guardfile_path
        File.join(Dir.pwd, 'Guardfile')
      end

      # The path to the `.Guardfile` that is located at
      # the users home directory.
      #
      # @return [String] the path to ~/.Guardfile
      #
      def home_guardfile_path
        File.expand_path(File.join('~', '.Guardfile'))
      end

      # The path to the user configuration `.guard.rb`
      # that is located at the users home directory.
      #
      # @return [String] the path to ~/.guard.rb
      #
      def user_config_path
        File.expand_path(File.join('~', '.guard.rb'))
      end

    end

    # Set notification options for the system notifications.
    # You can set multiple notification, which allows you to show local
    # system notifications and remote notifications with separate libraries.
    # You can also pass `:off` as library to turn off notifications.
    #
    # @example Define multiple notifications
    #   notification :growl_notify
    #   notification :ruby_gntp, :host => '192.168.1.5'
    #
    # @see Guard::Notifier for available notifier and its options.
    #
    # @param [Symbol, String] notifier the name of the notifier to use
    # @param [Hash] options the notification library options
    #
    def notification(notifier, options = {})
      ::Guard::Notifier.add_notification(notifier.to_sym, options, false)
    end

    # Sets the interactor to use.
    #
    # @example Turn off interactions
    #   interactor :off
    #
    # @param [Symbol,Hash] options either `:off` or a Hash with interactor options
    #
    def interactor(options)
      if options == :off
        ::Guard::Interactor.enabled = false

      elsif options.is_a?(Hash)
        ::Guard::Interactor.options = options

      else
        ::Guard::UI.deprecation(INTERACTOR_DEPRECATION)
      end
    end

    # Declares a group of Guard plugins to be run with `guard start --group group_name`.
    #
    # @example Declare two groups of Guard plugins
    #
    #   group 'backend' do
    #     guard 'spork'
    #     guard 'rspec'
    #   end
    #
    #   group 'frontend' do
    #     guard 'passenger'
    #     guard 'livereload'
    #   end
    #
    # @param [Symbol, String] name the group name called from the CLI
    # @param [Hash] options the options accepted by the group
    # @yield a block where you can declare several guards
    #
    # @see Guard.add_group
    # @see Dsl#guard
    # @see Guard::DslDescriber
    #
    def group(name, options = {})
      name = name.to_sym

      if block_given?
        ::Guard.add_group(name.to_s.downcase, options)
        @current_group = name

        yield if block_given?

        @current_group = nil
      end
    end

    # Declare a Guard plugin to be used when running `guard start`.
    #
    # The name parameter is usually the name of the gem without
    # the 'guard-' prefix.
    #
    # The available options are different for each Guard implementation.
    #
    # @example Declare a Guard
    #
    #   guard 'rspec' do
    #   end
    #
    # @param [String] name the Guard name
    # @param [Hash] options the options accepted by the Guard
    # @yield a block where you can declare several watch patterns and actions
    #
    # @see Guard.add_guard
    # @see Dsl#group
    # @see Dsl#watch
    # @see Guard::DslDescriber
    #
    def guard(name, options = {})
      @watchers  = []
      @callbacks = []
      @current_group ||= :default

      yield if block_given?

      options.update(:group => @current_group)
      ::Guard.add_guard(name.to_s.downcase, @watchers, @callbacks, options)
    end

    # Define a pattern to be watched in order to run actions on file modification.
    #
    # @example Declare watchers for a Guard
    #
    #   guard 'rspec' do
    #     watch('spec/spec_helper.rb')
    #     watch(%r{^.+_spec.rb})
    #     watch(%r{^app/controllers/(.+).rb}) { |m| 'spec/acceptance/#{m[1]}s_spec.rb' }
    #   end
    #
    # @param [String, Regexp] pattern the pattern to be watched by the guard
    # @yield a block to be run when the pattern is matched
    # @yieldparam [MatchData] m matches of the pattern
    # @yieldreturn a directory, a filename, an array of directories / filenames, or nothing (can be an arbitrary command)
    #
    # @see Guard::Watcher
    # @see Dsl#guard
    #
    def watch(pattern, &action)
      @watchers << ::Guard::Watcher.new(pattern, action)
    end

    # Define a callback to execute arbitrary code before or after any of
    # the `start`, `stop`, `reload`, `run_all`, `run_on_changes` `run_on_additions`, `run_on_modifications`
    # and `run_on_removals` plugin method.
    #
    # @param [Array] args the callback arguments
    # @yield a block with listeners
    #
    # @see Guard::Hook
    #
    def callback(*args, &listener)
      listener, events = args.size > 1 ? args : [listener, args[0]]
      @callbacks << { :events => events, :listener => listener }
    end

    # @deprecated Ignore certain paths globally.
    #
    # @example Ignore some paths
    #   ignore_paths ".git", ".svn"
    #
    # @param [Array] paths the list of paths to ignore
    #
    def ignore_paths(*paths)
      ::Guard::UI.deprecation(IGNORE_PATHS_DEPRECATION)
    end

    # Ignore certain paths globally.
    #
    # @example Ignore some paths
    #   ignore %r{^ignored/path/}, /man/
    #
    # @param [Regexp] regexps a pattern for ignoring paths
    #
    def ignore(*regexps)
      ::Guard.listener = ::Guard.listener.ignore(*regexps) if ::Guard.listener
    end

    # Replace ignored paths globally
    #
    # @example Ignore only these paths
    #   ignore! %r{^ignored/path/}, /man/
    #
    # @param [Regexp] regexps a pattern for ignoring paths
    #
    def ignore!(*regexps)
      ::Guard.listener = ::Guard.listener.ignore!(*regexps) if ::Guard.listener
    end

    # Filter certain paths globally.
    #
    # @example Filter some files
    #   filter /\.txt$/, /.*\.zip/
    #
    # @param [Regexp] regexps a pattern for filtering paths
    #
    def filter(*regexps)
      ::Guard.listener = ::Guard.listener.filter(*regexps) if ::Guard.listener
    end

    # Replace filtered paths globally.
    #
    # @example Filter only these files
    #   filter! /\.txt$/, /.*\.zip/
    #
    # @param [Regexp] regexps a pattern for filtering paths
    #
    def filter!(*regexps)
      ::Guard.listener = ::Guard.listener.filter!(*regexps) if ::Guard.listener
    end

    # Configure the Guard logger.
    #
    # * Log level must be either `:debug`, `:info`, `:warn` or `:error`.
    # * Template supports the following placeholders: `:time`, `:severity`, `:progname`, `:pid`, `:unit_of_work_id` and `:message`
    # * Time format directives are the same as Time#strftime or :milliseconds
    # * The `:only` and `:except` options must be a RegExp.
    #
    # @example Set the log level
    #   logger :level => :warn
    #
    # @example Set a custom log template
    #   logger :template => '[Guard - :severity - :progname - :time] :message'
    #
    # @example Set a custom time format
    #   logger :time_format => '%h'
    #
    # @example Limit logging to a Guard plugin
    #   logger :only => :jasmine
    #
    # @example Log all but not the messages from a specific Guard plugin
    #   logger :except => :jasmine
    #
    # @param [Hash] options the log options
    # @option options [String, Symbol] level the log level
    # @option options [String] template the logger template
    # @option options [String, Symbol] time_format the time format
    # @option options [RegExp] only show only messages from the matching Guard plugin
    # @option options [RegExp] except does not show messages from the matching Guard plugin
    #
    def logger(options)
      if options[:level]
        options[:level] = options[:level].to_sym

        unless [:debug, :info, :warn, :error].include? options[:level]
          ::Guard::UI.warning "Invalid log level `#{ options[:level] }` ignored. Please use either :debug, :info, :warn or :error."
          options.delete :level
        end
      end

      if options[:only] && options[:except]
        ::Guard::UI.warning 'You cannot specify the logger options :only and :except at the same time.'

        options.delete :only
        options.delete :except
      end

      # Convert the :only and :except options to a regular expression
      [:only, :except].each do |name|
        if options[name]
          list = [].push(options[name]).flatten.map { |plugin| Regexp.escape(plugin.to_s) }.join('|')
          options[name] = Regexp.new(list, Regexp::IGNORECASE)
        end
      end

      ::Guard::UI.options = ::Guard::UI.options.merge options
    end

    # Sets the default scope on startup
    #
    # @example Scope Guard to a single group
    #   scope :group => :frontend
    #
    # @example Scope Guard to multiple groups
    #   scope :groups => [:specs, :docs]
    #
    # @example Scope Guard to a single plugin
    #   scope :plugin => :test
    #
    # @example Scope Guard to multiple plugins
    #   scope :plugins => [:jasmine, :rspec]
    #
    # @param [Hash] scopes the scope for the groups and plugins
    #
    def scope(scopes = {})
      if ::Guard.options[:plugin].empty?
        ::Guard.options[:plugin] = [scopes[:plugin]] if scopes[:plugin]
        ::Guard.options[:plugin] = scopes[:plugins]  if scopes[:plugins]
      end

      if ::Guard.options[:group].empty?
        ::Guard.options[:group] = [scopes[:group]] if scopes[:group]
        ::Guard.options[:group] = scopes[:groups]  if scopes[:groups]
      end
    end

  end
end
