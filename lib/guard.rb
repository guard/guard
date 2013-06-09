require 'rbconfig'

require 'guard/deprecated_methods'
require 'guard/deprecator'
require 'guard/dsl'
require 'guard/group'
require 'guard/guardfile'
require 'guard/interactor'
require 'guard/notifier'
require 'guard/plugin_util'
require 'guard/runner'
require 'guard/setuper'
require 'guard/ui'
require 'guard/watcher'

# Guard is the main module for all Guard related modules and classes.
# Also Guard plugins should use this namespace.
#
module Guard

  WINDOWS  = RbConfig::CONFIG['host_os'] =~ %r!(msdos|mswin|djgpp|mingw)!
  DEV_NULL = WINDOWS ? 'NUL' : '/dev/null'

  extend DeprecatedMethods
  extend Setuper

  class << self
    attr_accessor :options, :evaluator, :interactor, :runner, :listener, :lock, :scope, :running

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
    # @see CLI#start
    #
    def start(options = {})
      setup(options)

      within_preserved_state do
        ::Guard::UI.debug 'Guard starts all plugins'
        runner.run(:start)
        ::Guard::UI.info "Guard is now watching at '#{ @watchdir }'"
        listener.start
      end
    end

    # Stop Guard listening to file changes.
    #
    def stop
      within_preserved_state do
        ::Guard::UI.debug 'Guard stops all plugins'
        runner.run(:stop)
        ::Guard::Notifier.turn_off
        ::Guard::UI.info 'Bye bye...', :reset => true
        listener.stop
        @running = false
      end
    end

    # Reload Guardfile and all Guard plugins currently enabled.
    # If no scope is given, then the Guardfile will be re-evaluated,
    # which results in a stop/start, which makes the reload obsolete.
    #
    # @param [Hash] scopes hash with a Guard plugin or a group scope
    #
    def reload(scopes = {})
      within_preserved_state do
        ::Guard::UI.clear(:force => true)
        ::Guard::UI.action_with_scopes('Reload', scopes)

        if scopes.empty?
          evaluator.reevaluate_guardfile
        else
          runner.run(:reload, scopes)
        end
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
    #   Guard.plugins('rspec')
    #   Guard.plugins(:rspec)
    #
    # @example Filter Guard plugins by Regexp
    #   Guard.plugins(/rsp.+/)
    #
    # @example Filter Guard plugins by Hash
    #   Guard.plugins(:name => 'rspec', :group => 'backend')
    #
    # @param [String, Symbol, Regexp, Hash] filter the filter to apply to the Guard plugins
    # @return [Plugin, Array<Plugin>] the filtered Guard plugin(s)
    #
    def plugins(filter = nil)
      @plugins ||= []

      return @plugins if filter.nil?

      filtered_plugins = case filter
                        when String, Symbol
                          @plugins.find_all do |plugin|
                            plugin.name == filter.to_s.downcase.gsub('-', '')
                          end
                        when Regexp
                          @plugins.find_all do |plugin|
                            plugin.name =~ filter
                          end
                        when Hash
                          @plugins.find_all do |plugin|
                            filter.all? do |k, v|
                              case k
                              when :name
                                plugin.name == v.to_s.downcase.gsub('-', '')
                              when :group
                                plugin.group.name == v.to_sym
                              end
                            end
                          end
                        end

      _smart_accessor_return_value(filtered_plugins)
    end

    # Smart accessor for retrieving a specific plugin group or several plugin groups at once.
    #
    # @see Guard.plugins
    #
    # @example Filter groups by String or Symbol
    #   Guard.groups('backend')
    #   Guard.groups(:backend)
    #
    # @example Filter groups by Regexp
    #   Guard.groups(/(back|front)end/)
    #
    # @param [String, Symbol, Regexp] filter the filter to apply to the Groups
    # @return [Group, Array<Group>] the filtered group(s)
    #
    def groups(filter = nil)
      return @groups if filter.nil?

      filtered_groups = case filter
                        when String, Symbol
                          @groups.find_all { |group| group.name == filter.to_sym }
                        when Regexp
                          @groups.find_all { |group| group.name.to_s =~ filter }
                        end

      _smart_accessor_return_value(filtered_groups)
    end

    # Add a Guard plugin to use.
    #
    # @param [String] name the Guard name
    # @param [Hash] options the plugin options (see the given Guard documentation)
    # @option options [String] group the group to which the Guard plugin belongs
    # @option options [Array<Watcher>] watchers the list of declared watchers
    # @option options [Array<Hash>] callbacks the list of callbacks
    # @return [Plugin] the added Guard plugin
    # @see Plugin
    #
    def add_guard(name, options = {})
      guard_plugin_instance = ::Guard::PluginUtil.new(name).initialize_plugin(options)
      @guards << guard_plugin_instance

      guard_plugin_instance
    end

    # Add a Guard plugin group.
    #
    # @param [String] name the group name
    # @option options [Boolean] halt_on_fail if a task execution
    #   should be halted for all Guard plugins in this group if
    #   one Guard throws `:task_has_failed`
    # @return [Group] the group added (or retrieved from the `@groups`
    #   variable if already present)
    #
    # @see Group
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
    # @param [Boolean] restart_interactor whether to restart the interactor or
    #   not
    # @yield the block to run
    #
    def within_preserved_state
      lock.synchronize do
        begin
          interactor.stop if interactor
          @result = yield
        rescue Interrupt
          # Bring back Pry when the block is halted with Ctrl-C
        end

        interactor.start if running
      end

      @result
    end
    private

    # Given an array, returns either:
    #
    #   * nil if `results` is empty,
    #   * the first element of `results` if `results` has only one element,
    #   * `results` otherwise.
    #
    # @return [nil, Object, Array<Object>]
    #
    def _smart_accessor_return_value(results)
      if results.empty?
        nil
      elsif results.one?
        results[0]
      else
        results
      end
    end

  end
end
