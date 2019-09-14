require "guard/plugin_util"
require "guard/group"
require "guard/api"
require "guard/plugin"

module Guard
  # @private api
  module Internals
    class Plugins
      def initialize(engine:)
        @engine = engine
        @plugins = []
      end

      def all(filter = nil)
        return @plugins if filter.nil?
        matcher = matcher_for(filter)
        @plugins.select { |plugin| matcher.call(plugin) }
      end

      def find(filter = nil)
        all(filter)[0]
      end

      def remove(plugin)
        @plugins.delete(plugin)
      end

      # TODO: should it allow duplicates? (probably yes because of different
      # configs or groups)
      def add(name, options)
        plugin_util = PluginUtil.new(engine: @engine, name: name)
        plugin = plugin_util.initialize_plugin(options)
        @plugins << plugin
        plugin
      end

      private

      def matcher_for(filter)
        case filter
        when String, Symbol
          shortname = filter.to_s.downcase.delete("-")
          ->(plugin) { plugin.name == shortname }
        when Regexp
          ->(plugin) { plugin.name =~ filter }
        when Hash
          lambda do |plugin|
            filter.all? do |k, v|
              case k
              when :name
                plugin.name == v.to_s.downcase.delete("-")
              when :group
                plugin.group.name == v.to_sym
              end
            end
          end
        end
      end
    end
  end
end
