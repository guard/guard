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
    attr_accessor :runner, :listener, :lock, :scope, :running

    # Smart accessor for retrieving specific plugins at once.
    #
    # @see Guard.plugin
    # @see Guard.group
    # @see Guard.groups
    #
    # @example Filter plugins by String or Symbol
    #   Guard.plugins('rspec')
    #   Guard.plugins(:rspec)
    #
    # @example Filter plugins by Regexp
    #   Guard.plugins(/rsp.+/)
    #
    # @example Filter plugins by Hash
    #   Guard.plugins(name: 'rspec', group: 'backend')
    #
    # @param [String, Symbol, Regexp, Hash] filter the filter to apply to the plugins
    # @return [Plugin, Array<Plugin>] the filtered plugin(s)
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

      filtered_plugins
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

    # Smart accessor for retrieving specific groups at once.
    #
    # @see Guard.plugin
    # @see Guard.plugins
    # @see Guard.group
    #
    # @example Filter groups by String or Symbol
    #   Guard.groups('backend')
    #   Guard.groups(:backend)
    #
    # @example Filter groups by Regexp
    #   Guard.groups(/(back|front)end/)
    #
    # @param [String, Symbol, Regexp] filter the filter to apply to the Groups
    # @return [Array<Group>] the filtered group(s)
    #
    def groups(filter = nil)
      @groups ||= []

      return @groups if filter.nil?

      filtered_groups = case filter
                        when String, Symbol
                          @groups.find_all { |group| group.name == filter.to_sym }
                        when Regexp
                          @groups.find_all { |group| group.name.to_s =~ filter }
                        end

      filtered_groups
    end

    # Smart accessor for retrieving a specific group.
    #
    # @see Guard.plugin
    # @see Guard.plugins
    # @see Guard.groups
    #
    # @example Find a group by String or Symbol
    #   Guard.group('backend')
    #   Guard.group(:backend)
    #
    # @example Find a group by Regexp
    #   Guard.group(/(back|front)end/)
    #
    # @param [String, Symbol, Regexp] filter the filter for finding the group
    # @return [Group] the group found, nil otherwise
    #
    def group(filter)
      groups(filter).first
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
      unless group = group(name)
        group = ::Guard::Group.new(name, options)
        @groups << group
      end

      group
    end

  end
end
