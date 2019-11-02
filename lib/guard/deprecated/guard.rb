# frozen_string_literal: true

require "guard/config"
fail "Deprecations disabled (strict mode)" if Guard::Config.new.strict?

require "forwardable"

require "guard/deprecated/options"
require "guard/ui"
require "guard/internals/session"
require "guard/internals/state"
require "guard/guardfile/evaluator"

module Guard
  # @deprecated Every method in this module is deprecated
  module Deprecated
    module Guard
      def self.add_deprecated(klass)
        klass.send(:extend, ClassMethods)
      end

      module ClassMethods
        MORE_INFO_ON_UPGRADING_TO_GUARD_2 = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          For more information on how to upgrade for Guard 2.0, please head
          over to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0%s
        DEPRECATION_NOTICE

        # @deprecated Use `Guard.plugins(filter)` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        GUARDS = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.guards(filter)' is deprecated.

          Please use 'Guard.plugins(filter)' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        DEPRECATION_NOTICE

        def guards(filter = nil)
          ::Guard::UI.deprecation(GUARDS)
          ::Guard.state.session.plugins.all(filter)
        end

        # @deprecated Use `Guard.add_plugin(name, options = {})` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        ADD_GUARD = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.add_guard(name, options = {})' is
          deprecated.

          Please use 'Guard.add_plugin(name, options = {})' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        DEPRECATION_NOTICE

        def add_guard(*args)
          ::Guard::UI.deprecation(ADD_GUARD)
          add_plugin(*args)
        end

        # @deprecated Use
        #   `Guard::PluginUtil.new(name).plugin_class(fail_gracefully:
        #   fail_gracefully)` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        GET_GUARD_CLASS = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.get_guard_class(name, fail_gracefully
          = false)' is deprecated and is now always on.

          Please use 'Guard::PluginUtil.new(name).plugin_class(fail_gracefully:
          fail_gracefully)' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        DEPRECATION_NOTICE

        def get_guard_class(name, fail_gracefully = false)
          UI.deprecation(GET_GUARD_CLASS)
          PluginUtil.new(name).plugin_class(fail_gracefully: fail_gracefully)
        end

        # @deprecated Use `Guard::PluginUtil.new(name).plugin_location` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        LOCATE_GUARD = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.locate_guard(name)' is deprecated.

          Please use 'Guard::PluginUtil.new(name).plugin_location' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        DEPRECATION_NOTICE

        def locate_guard(name)
          UI.deprecation(LOCATE_GUARD)
          PluginUtil.new(name).plugin_location
        end

        # @deprecated Use `Guard::PluginUtil.plugin_names` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        # Deprecator message for the `Guard.guard_gem_names` method
        GUARD_GEM_NAMES = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.guard_gem_names' is deprecated.

          Please use 'Guard::PluginUtil.plugin_names' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
        DEPRECATION_NOTICE

        def guard_gem_names
          UI.deprecation(GUARD_GEM_NAMES)
          PluginUtil.plugin_names
        end

        RUNNING = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.7.1 it was discovered that Guard.running was
          never initialized or used internally.
        DEPRECATION_NOTICE

        def running
          UI.deprecation(RUNNING)
          nil
        end

        LOCK = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.7.1 it was discovered that this accessor was
          never initialized or used internally.
        DEPRECATION_NOTICE
        def lock
          UI.deprecation(LOCK)
        end

        LISTENER_ASSIGN = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          listener= should not be used
        DEPRECATION_NOTICE

        def listener=(_listener)
          UI.deprecation(LISTENER_ASSIGN)
          ::Guard.listener
        end

        EVALUATOR = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        DEPRECATION_NOTICE

        def evaluator
          UI.deprecation(EVALUATOR)
          options = ::Guard.state.session.evaluator_options
          ::Guard::Guardfile::Evaluator.new(options)
        end

        RESET_EVALUATOR = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        DEPRECATION_NOTICE

        def reset_evaluator(_options)
          UI.deprecation(RESET_EVALUATOR)
        end

        RUNNER = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        DEPRECATION_NOTICE

        def runner
          UI.deprecation(RUNNER)
          ::Guard::Runner.new
        end

        EVALUATE_GUARDFILE = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        DEPRECATION_NOTICE

        def evaluate_guardfile
          UI.deprecation(EVALUATE_GUARDFILE)
          options = ::Guard.state.session.evaluator_options
          evaluator = ::Guard::Guardfile::Evaluator.new(options)
          evaluator.evaluate
          msg = "No plugins found in Guardfile, please add at least one."
          ::Guard::UI.error msg if _pluginless_guardfile?
        end

        OPTIONS = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          Starting with Guard 2.9.0 Guard.options is deprecated and ideally you
          should be able to set specific options through an API or a DSL
          method. Feel free to add feature requests if there's something
          missing.
        DEPRECATION_NOTICE

        def options
          UI.deprecation(OPTIONS)

          ::Guard::Deprecated::Options.new
        end

        ADD_GROUP = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          add_group is deprecated since 2.10.0 in favor of
          Guard.state.session.groups.add
        DEPRECATION_NOTICE

        def add_group(name, options = {})
          UI.deprecation(ADD_GROUP)
          ::Guard.state.session.groups.add(name, options)
        end

        ADD_PLUGIN = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          add_plugin is deprecated since 2.10.0 in favor of
          Guard.state.session.plugins.add
        DEPRECATION_NOTICE

        def add_plugin(name, options = {})
          UI.deprecation(ADD_PLUGIN)
          ::Guard.state.session.plugins.add(name, options)
        end

        GROUP = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          group is deprecated since 2.10.0 in favor of
          Guard.state.session.group.add(filter).first
        DEPRECATION_NOTICE

        def group(filter)
          UI.deprecation(GROUP)
          ::Guard.state.session.groups.all(filter).first
        end

        PLUGIN = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          plugin is deprecated since 2.10.0 in favor of
          Guard.state.session.group.add(filter).first
        DEPRECATION_NOTICE

        def plugin(filter)
          UI.deprecation(PLUGIN)
          ::Guard.state.session.plugins.all(filter).first
        end

        GROUPS = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          group is deprecated since 2.10.0 in favor of
          Guard.state.session.groups.all(filter)
        DEPRECATION_NOTICE

        def groups(filter)
          UI.deprecation(GROUPS)
          ::Guard.state.session.groups.all(filter)
        end

        PLUGINS = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          plugins is deprecated since 2.10.0 in favor of
          Guard.state.session.plugins.all(filter)
        DEPRECATION_NOTICE

        def plugins(filter)
          UI.deprecation(PLUGINS)
          ::Guard.state.session.plugins.all(filter)
        end

        SCOPE = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          scope is deprecated since 2.10.0 in favor of
          Guard.state.scope.to_hash
        DEPRECATION_NOTICE

        def scope
          UI.deprecation(SCOPE)
          ::Guard.state.scope.to_hash
        end

        SCOPE_ASSIGN = <<-DEPRECATION_NOTICE.gsub(/^\s*/, "")
          scope= is deprecated since 2.10.0 in favor of
          Guard.state.scope.to_hash
        DEPRECATION_NOTICE

        def scope=(scope)
          UI.deprecation(SCOPE_ASSIGN)
          ::Guard.state.session.interactor_scope = scope
        end
      end
    end
  end
end
