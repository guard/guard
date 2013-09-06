require 'rbconfig'

require 'guard/commander'
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

  extend Commander
  extend DeprecatedMethods
  extend Setuper

  class << self
    attr_accessor :options, :evaluator, :interactor, :runner, :listener, :lock, :scope, :running

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
    #   Guard.plugins(name: 'rspec', group: 'backend')
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

    # Smart accessor for retrieving a specific plugin.
    #
    # @see Guard.plugins
    # @see Guard.group
    # @see Guard.groups
    #
    # @example Find a plugin by String or Symbol
    #   Guard.plugin('rspec')
    #   Guard.plugin(:rspec)
    #
    # @example Find a plugin by Regexp
    #   Guard.plugin(/rsp.+/)
    #
    # @example Find a plugin by Hash
    #   Guard.plugin(name: 'rspec', group: 'backend')
    #
    # @param [String, Symbol, Regexp, Hash] filter the filter for finding the plugin
    #   the Guard plugin
    # @return [Plugin, nil] the plugin found, nil otherwise
    #
    def plugin(filter)
      plugins(filter).first
    end

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
    def add_plugin(name, options = {})
      plugin_instance = ::Guard::PluginUtil.new(name).initialize_plugin(options)
      @plugins << plugin_instance

      plugin_instance
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
