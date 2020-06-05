# frozen_string_literal: true

module Guard
  # @private api
  module Internals
    class Scope
      def initialize(engine)
        @engine = engine
      end

      def grouped_plugins(scopes = { plugins: [], groups: [] })
        plugins = _instantiate_plugins(scopes)
        return plugins.map { |plugin| [nil, [plugin]] } if plugins

        _instantiate_groups(scopes).map do |group|
          [group, engine.plugins.all(group: group.name)]
        end
      end

      def titles(scopes = nil)
        hash = scopes || _to_hash
        plugins = hash[:plugins]
        groups = hash[:groups]

        if plugins
          plugins = _instantiate_plugins(hash)
          return plugins.map(&:title) if plugins&.any?
        elsif groups
          groups = _instantiate_groups(hash)
          return groups.map(&:title) if groups&.any?
        end

        ["all"]
      end

      private

      attr_reader :engine

      def _to_hash
        {
          plugins: _hashify_scope(:plugins),
          groups: _hashify_scope(:groups)
        }.dup.freeze
      end

      # TODO: let the Plugins and Groups classes handle this?
      def _hashify_scope(type)
        session = engine.session
        interactor = session.interactor_scopes[type]
        cmdline = session.cmdline_scopes[type]
        guardfile = session.guardfile_scopes[type]

        # TODO: session should decide whether to use cmdline or guardfile -
        # since it has access to both variables
        items = [interactor, cmdline, guardfile].detect do |source|
          !source.empty?
        end

        Array(items).map do |obj|
          if obj.respond_to?(:name)
            obj
          else
            engine.public_send(type).all(obj).first
          end
        end.compact
      end

      def _instantiate_plugins(scope)
        plugin_names = _find_non_empty_scope(:plugins, scope) || engine.plugins.all

        if plugin_names
          Array(plugin_names).map { |plugin_name| _instantiate(:plugins, plugin_name) }
        end
      end

      def _instantiate_groups(scope)
        group_names = _find_non_empty_scope(:groups, scope) || engine.groups.all

        Array(group_names + [:common]).uniq.map { |group_name| _instantiate(:groups, group_name) }
      end

      def _instantiate(type, obj)
        return obj unless obj.is_a?(Symbol) || obj.is_a?(String)

        engine.public_send(type).all(obj).first
      end

      def _find_non_empty_scope(type, local_scope)
        [Array(local_scope[type]), _to_hash[type]].map(&:compact).detect(&:any?)
      end
    end
  end
end
