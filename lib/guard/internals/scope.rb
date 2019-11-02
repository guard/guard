# frozen_string_literal: true

require "guard"

module Guard
  # @private api
  module Internals
    class Scope
      def to_hash
        {
          plugins: _hashify_scope(:plugin),
          groups: _hashify_scope(:group)
        }.dup.freeze
      end

      # TODO: refactor
      # TODO: no coverage here!!
      def grouped_plugins(scope = { plugins: [], groups: [] })
        plugins = _instantiate_plugins(scope)
        return plugins.map { |plugin| [nil, [plugin]] } if plugins

        _instantiate_groups(scope).map do |group|
          [group, _session.plugins.all(group: group.name)]
        end
      end

      def titles(scope = nil)
        hash = scope || to_hash
        plugins = hash[:plugins]
        groups = hash[:groups]
        return plugins.map(&:title) unless plugins.nil? || plugins.empty?
        return hash[:groups].map(&:title) unless groups.nil? || groups.empty?

        ["all"]
      end

      private

      def _session
        @session ||= Guard.state.session
      end

      # TODO: let the Plugins and Groups classes handle this?
      # TODO: why even instantiate?? just to check if it exists?
      def _hashify_scope(type)
        # TODO: get cmdline passed to initialize above?
        cmdline = _session.cmdline_scopes[type]
        guardfile = _session.guardfile_scopes[type]
        interactor = _session.interactor_scopes[type]

        # TODO: _session should decide whether to use cmdline or guardfile -
        # since it has access to both variables
        items = [interactor, cmdline, guardfile].detect do |source|
          !source.empty?
        end

        # TODO: not tested when groups/plugins given don't exist

        # TODO: should already be instantiated
        Array(items).map do |obj|
          if obj.respond_to?(:name)
            obj
          else
            name = obj
            (type == :group ? _groups : _plugins).all(name).first
          end
        end.compact
      end

      def _instantiate_plugins(scope)
        plugin_names = _find_non_empty_scope(:plugins, scope)

        if plugin_names
          Array(plugin_names).map { |plugin_name| _instantiate(:plugin, plugin_name) }
        end
      end

      def _instantiate_groups(scope)
        group_names = _find_non_empty_scope(:groups, scope) || _session.groups.all

        Array(group_names + [:common]).uniq.map { |group_name| _instantiate(:group, group_name) }
      end

      def _instantiate(type, obj)
        # TODO: no coverage
        return obj unless obj.is_a?(Symbol) || obj.is_a?(String)

        _session.send("#{type}s".to_sym).all(obj).first
      end

      def _find_non_empty_scope(type, local_scope)
        [Array(local_scope[type]), to_hash[type]].map(&:compact).detect(&:any?)
      end

      def _groups
        _session.groups
      end

      def _plugins
        _session.plugins
      end
    end
  end
end
