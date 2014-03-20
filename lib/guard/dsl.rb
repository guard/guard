require 'guard/guardfile'
require 'guard/interactor'
require 'guard/notifier'
require 'guard/ui'
require 'guard/watcher'

module Guard

  # The Dsl class provides the methods that are used in each `Guardfile` to
  # describe the behaviour of Guard.
  #
  # The main keywords of the DSL are {#guard} and {#watch}. These are necessary
  # to define the used Guard plugins and the file changes they are watching.
  #
  # You can optionally group the Guard plugins with the {#group} keyword and
  # ignore and filter certain paths with the {#ignore} and {#filter} keywords.
  #
  # You can set your preferred system notification library with {#notification}
  # and pass some optional configuration options for the library. If you don't
  # configure a library, Guard will automatically pick one with default options
  # (if you don't want notifications, specify `:off` as library). Please see
  # {Notifier} for more information about the supported libraries.
  #
  # A more advanced DSL use is the {#callback} keyword that allows you to
  # execute arbitrary code before or after any of the {Plugin::Base#start},
  # {Plugin::Base#stop}, {Plugin::Base#reload}, {Plugin::Base#run_all},
  # {Plugin::Base#run_on_changes}, {Plugin::Base#run_on_additions},
  # {Plugin::Base#run_on_modifications} and {Plugin::Base#run_on_removals}
  # Guard plugins method.
  # You can even insert more hooks inside these methods. Please [checkout the
  # Wiki page](https://github.com/guard/guard/wiki/Hooks-and-callbacks) for
  # more details.
  #
  # The DSL will also evaluate normal Ruby code.
  #
  # There are two possible locations for the `Guardfile`:
  #
  # * The `Guardfile` in the current directory where Guard has been started
  # * The `.Guardfile` in your home directory.
  #
  # In addition, if a user configuration `.guard.rb` in your home directory is
  # found, it will be appended to the current project `Guardfile`.
  #
  # @see https://github.com/guard/guard/wiki/Guardfile-examples
  #
  class Dsl

    # @deprecated Use
    #   `Guard::Guardfile::Evaluator.new(options).evaluate_guardfile` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    def self.evaluate_guardfile(options = {})
      ::Guard::UI.deprecation(::Guard::Deprecator::EVALUATE_GUARDFILE_DEPRECATION)
      ::Guard::Guardfile::Evaluator.new(options).evaluate_guardfile
    end

    # Set notification options for the system notifications.
    # You can set multiple notifications, which allows you to show local
    # system notifications and remote notifications with separate libraries.
    # You can also pass `:off` as library to turn off notifications.
    #
    # @example Define multiple notifications
    #   notification :growl_notify
    #   notification :ruby_gntp, host: '192.168.1.5'
    #
    # @param [Symbol, String] notifier the name of the notifier to use
    # @param [Hash] options the notification library options
    #
    # @see Guard::Notifier for available notifier and its options.
    #
    def notification(notifier, options = {})
      ::Guard::Notifier.add_notifier(notifier.to_sym, options.merge(silent: false))
    end

    # Sets the interactor options or disable the interactor.
    #
    # @example Pass options to the interactor
    #   interactor option1: 'value1', option2: 'value2'
    #
    # @example Turn off interactions
    #   interactor :off
    #
    # @param [Symbol, Hash] options either `:off` or a Hash with interactor
    #   options
    #
    def interactor(options)
      case options
      when :off
        ::Guard::Interactor.enabled = false
      when Hash
        ::Guard::Interactor.options = options
      end
    end

    # Declares a group of Guard plugins to be run with `guard start --group
    #   group_name`.
    #
    # @example Declare two groups of Guard plugins
    #   group :backend do
    #     guard :spork
    #     guard :rspec
    #   end
    #
    #   group :frontend do
    #     guard :passenger
    #     guard :livereload
    #   end
    #
    # @param [Symbol, String, Array<Symbol, String>] name the group name called from the CLI
    # @param [Hash] options the options accepted by the group
    # @yield a block where you can declare several Guard plugins
    #
    # @see Group
    # @see Guard.add_group
    # @see #guard
    #
    def group(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      groups = args

      groups.each do |group|
        raise ArgumentError, "'all' is not an allowed group name!" if group.to_sym == :all
      end

      if block_given?
        groups.each do |group|
          ::Guard.add_group(group, options)
        end

        @current_groups ||= []
        @current_groups.push(groups)

        yield

        @current_groups.pop
      else
        ::Guard::UI.error "No Guard plugins found in the group '#{ groups.join(', ') }', please add at least one."
      end
    end

    # Declares a Guard plugin to be used when running `guard start`.
    #
    # The name parameter is usually the name of the gem without
    # the 'guard-' prefix.
    #
    # The available options are different for each Guard implementation.
    #
    # @example Declare a Guard without `watch` patterns
    #   guard :rspec
    #
    # @example Declare a Guard with a `watch` pattern
    #   guard :rspec do
    #     watch %r{.*_spec.rb}
    #   end
    #
    # @param [String] name the Guard plugin name
    # @param [Hash] options the options accepted by the Guard plugin
    # @yield a block where you can declare several watch patterns and actions
    #
    # @see Plugin
    # @see Guard.add_plugin
    # @see #watch
    # @see #group
    #
    def guard(name, options = {})
      @plugin_options = options.merge(watchers: [], callbacks: [])

      yield if block_given?

      groups = @current_groups && @current_groups.last || [:default]
      groups.each do |group|
        ::Guard.add_plugin(name, @plugin_options.merge(group: group))
      end

      @plugin_options = nil
    end

    # Defines a pattern to be watched in order to run actions on file modification.
    #
    # @example Declare watchers for a Guard
    #   guard :rspec do
    #     watch('spec/spec_helper.rb')
    #     watch(%r{^.+_spec.rb})
    #     watch(%r{^app/controllers/(.+).rb}) { |m| 'spec/acceptance/#{m[1]}s_spec.rb' }
    #   end
    #
    # @example Declare global watchers outside of a Guard
    #   watch(%r{^(.+)$}) { |m| puts "#{m[1]} changed." }
    #
    # @param [String, Regexp] pattern the pattern that Guard must watch for modification
    # @yield a block to be run when the pattern is matched
    # @yieldparam [MatchData] m matches of the pattern
    # @yieldreturn a directory, a filename, an array of directories / filenames, or nothing (can be an arbitrary command)
    #
    # @see Guard::Watcher
    # @see #guard
    #
    def watch(pattern, &action)
      # Allow watches in the global scope (to execute arbitrary commands) by
      # building a generic Guard::Plugin.
      return guard(:plugin) { watch(pattern, &action) } unless @plugin_options

      @plugin_options[:watchers] << ::Guard::Watcher.new(pattern, action)
    end

    # Defines a callback to execute arbitrary code before or after any of
    # the `start`, `stop`, `reload`, `run_all`, `run_on_changes`,
    # `run_on_additions`, `run_on_modifications` and `run_on_removals` plugin
    # method.
    #
    # @example Define a callback that'll be called before the `reload` action.
    #   callback(:reload_begin) { puts "Let's reload!" }
    #
    # @example Define a callback that'll be called before the `start` and `stop` actions.
    #   my_lambda = lambda { |plugin, event, *args| puts "Let's #{event} #{plugin} with #{args}!" }
    #   callback(my_lambda, [:start_begin, :start_end])
    #
    # @param [Array] args the callback arguments
    # @yield a callback block
    #
    # @see Guard::Hooker
    #
    def callback(*args, &block)
      fail "callback must be called within a guard block" unless @plugin_options

      block, events = if args.size > 1
        # block must be the first argument in that case, the yielded block is
        # ignored
        args
      else
        [block, args[0]]
      end
      @plugin_options[:callbacks] << { events: events, listener: block }
    end

    # Ignores certain paths globally.
    #
    # @example Ignore some paths
    #   ignore %r{^ignored/path/}, /man/
    #
    # @param [Regexp] regexps a pattern (or list of patterns) for ignoring paths
    #
    def ignore(*regexps)
      ::Guard.listener.ignore(regexps) if ::Guard.listener
    end
    alias filter ignore

    # Replaces ignored paths globally
    #
    # @example Ignore only these paths
    #   ignore! %r{^ignored/path/}, /man/
    #
    # @param [Regexp] regexps a pattern (or list of patterns) for ignoring paths
    #
    def ignore!(*regexps)
      @ignore_regexps ||= []
      @ignore_regexps << regexps
      ::Guard.listener.ignore!(@ignore_regexps) if ::Guard.listener
    end
    alias filter! ignore!

    # Configures the Guard logger.
    #
    # * Log level must be either `:debug`, `:info`, `:warn` or `:error`.
    # * Template supports the following placeholders: `:time`, `:severity`,
    #   `:progname`, `:pid`, `:unit_of_work_id` and `:message`.
    # * Time format directives are the same as `Time#strftime` or
    #   `:milliseconds`.
    # * The `:only` and `:except` options must be a `RegExp`.
    #
    # @example Set the log level
    #   logger level: :warn
    #
    # @example Set a custom log template
    #   logger template: '[Guard - :severity - :progname - :time] :message'
    #
    # @example Set a custom time format
    #   logger time_format: '%h'
    #
    # @example Limit logging to a Guard plugin
    #   logger only: :jasmine
    #
    # @example Log all but not the messages from a specific Guard plugin
    #   logger except: :jasmine
    #
    # @param [Hash] options the log options
    # @option options [String, Symbol] level the log level
    # @option options [String] template the logger template
    # @option options [String, Symbol] time_format the time format
    # @option options [Regexp] only show only messages from the matching Guard
    #   plugin
    # @option options [Regexp] except does not show messages from the matching
    #   Guard plugin
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

      ::Guard::UI.options.merge!(options)
    end

    # Sets the default scope on startup
    #
    # @example Scope Guard to a single group
    #   scope group: :frontend
    #
    # @example Scope Guard to multiple groups
    #   scope groups: [:specs, :docs]
    #
    # @example Scope Guard to a single plugin
    #   scope plugin: :test
    #
    # @example Scope Guard to multiple plugins
    #   scope plugins: [:jasmine, :rspec]
    #
    # @param [Hash] scopes the scope for the groups and plugins
    #
    def scope(scope = {})
      scope[:plugins] = Array(scope[:plugins] || scope[:plugin] || [])
      scope[:groups] = Array(scope[:groups] || scope[:group] || [])
      ::Guard.setup_scope(scope)
    end

  end
end
