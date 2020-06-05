# frozen_string_literal: true

require "guard/plugin_util"

module Guard
  # @private api
  module Internals
    class Plugins
      def initialize(engine)
        @engine = engine
        @plugins = []
      end

      def add(name, options)
        PluginUtil.new(engine, name).initialize_plugin(options).tap do |plugin|
          @plugins << plugin
        end
      end

      def remove(plugin)
        @plugins.delete(plugin)
      end

      def all(filter = nil)
        return @plugins unless filter

        matcher = matcher_for(filter)
        @plugins.select { |plugin| matcher.call(plugin) }
      end

      private

      attr_reader :engine

      def matcher_for(filter)
        case filter
        when String, Symbol
          shortname = filter.to_s.downcase
          ->(plugin) { plugin.name == shortname }
        when Regexp
          ->(plugin) { plugin.name =~ filter }
        when Hash
          lambda do |plugin|
            filter.all? do |k, v|
              case k
              when :name
                plugin.name == v.to_s.downcase
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
