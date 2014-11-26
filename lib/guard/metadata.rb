require "guard/group"

require "guard/plugin_util"

# TODO: should not be necessary
require "guard/internals/helpers"

module Guard
  extend Internals::Helpers

  # TODO: change to a normal class
  class << self
    DEFAULT_GROUPS = [:common, :default]

    DEFAULT_OPTIONS = {
      clear: false,
      notify: true,
      debug: false,
      group: [],
      plugin: [],
      watchdir: nil,
      guardfile: nil,
      no_interactions: false,
      no_bundler_warning: false,
      latency: nil,
      force_polling: false,
      wait_for_delay: nil,
      listen_on: nil
    }

    def add_group(name, options = {})
      unless (group = group(name))
        group = Group.new(name, options)
        @groups << group
      end

      group
    end

    def group(filter)
      groups(filter).first
    end

    def groups(filter = nil)
      @groups ||= []

      return @groups if filter.nil?

      case filter
      when String, Symbol
        @groups.select { |group| group.name == filter.to_sym }
      when Regexp
        @groups.select { |group| group.name.to_s =~ filter }
      else
        fail "Invalid filter: #{filter.inspect}"
      end
    end

    # TODO: remove
    def _reset_for_tests
      @options = nil
      @queue = nil
      @watchdirs = nil
      @watchdirs = nil
      @listener = nil
      @interactor = nil
      @scope = nil
    end

    # TODO: remove
    def clear_options
      @options = nil
    end

    # TODO: remove
    def reset_groups
      @groups = DEFAULT_GROUPS.map { |name| Group.new(name) }
    end

    # TODO: remove
    def reset_plugins
      @plugins = []
    end

    def plugins(filter = nil)
      @plugins ||= []

      return @plugins if filter.nil?

      filtered_plugins = case filter
                         when String, Symbol
                           @plugins.select do |plugin|
                             plugin.name == filter.to_s.downcase.gsub("-", "")
                           end
                         when Regexp
                           @plugins.select do |plugin|
                             plugin.name =~ filter
                           end
                         when Hash
                           @plugins.select do |plugin|
                             filter.all? do |k, v|
                               case k
                               when :name
                                 plugin.name == v.to_s.downcase.gsub("-", "")
                               when :group
                                 plugin.group.name == v.to_sym
                               end
                             end
                           end
                         end

      filtered_plugins
    end

    def scope
      fail "::Guard.setup() not called" if @scope.nil?
      @scope.dup.freeze
    end

    def plugin(filter)
      plugins(filter).first
    end

    # Used by runner to remove a failed plugin
    def remove_plugin(plugin)
      # TODO: coverage/aruba
      @plugins.delete(plugin)
    end

    # TODO: move elsewhere
    def add_builtin_plugins(guardfile)
      return unless guardfile

      pattern = _relative_pathname(guardfile).to_s
      watcher = ::Guard::Watcher.new(pattern)
      ::Guard.add_plugin(:reevaluator, watchers: [watcher], group: :common)
    end

    def add_plugin(name, options = {})
      instance = ::Guard::PluginUtil.new(name).initialize_plugin(options)
      @plugins << instance
      instance
    end

    def reset_scope
      # calls Guard.scope=() to set the instance variable directly, as opposed
      # to Guard.scope()
      ::Guard.scope = { groups: [], plugins: [] }
    end

    # Called by Pry scope command

    def scope=(new_scope)
      @scope = new_scope
      @scope.dup.freeze
    end

    # Used to merge CLI options with Setuper defaults
    def reset_options(new_options)
      @options = ::Guard::Options.new(new_options, DEFAULT_OPTIONS)
    end

    def save_scope
      # This actually replaces scope from command line,
      # so scope set by 'scope' Pry command will be reset
      @saved_scope = _prepare_scope(::Guard.scope)
    end

    def restore_scope
      ::Guard.setup_scope(@saved_scope || {})
    end

    private

    def _prepare_scope(new_scope)
      fail "Guard::setup() not called!" if options.nil?
      {
        plugins: _scope_names(new_scope, :plugin),
        groups: _scope_names(new_scope, :group)
      }
    end

    def _scope_names(new_scope, name)
      items = Array(options[name])
      items = Array(new_scope[:"#{name}s"] || new_scope[name]) if items.empty?
      # Convert objects to names
      items.map { |p| p.respond_to?(:name) ? p.name : p }
    end
  end
end
