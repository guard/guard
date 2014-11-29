require "guard/config"
fail "Deprecations disabled (strict mode)" if Guard::Config.new.strict?

require "guard/ui"
require "guard/plugin_util"
require "guard/guardfile/evaluator"

module Guard
  # @deprecated Every method in this module is deprecated
  module Deprecated
    module Guard
      def self.add_deprecated(klass)
        klass.send(:extend, ClassMethods)
      end

      module ClassMethods
        MORE_INFO_ON_UPGRADING_TO_GUARD_2 = <<-EOS.gsub(/^\s*/, "")
          For more information on how to upgrade for Guard 2.0, please head
          over to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0%s
        EOS

        # @deprecated Use `Guard.plugins(filter)` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        GUARDS = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.guards(filter)' is deprecated.

          Please use 'Guard.plugins(filter)' instead.

            #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % "#deprecated-methods"}
        EOS

        def guards(filter = nil)
          ::Guard::UI.deprecation(GUARDS)
          plugins(filter)
        end

        # @deprecated Use `Guard.add_plugin(name, options = {})` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        ADD_GUARD = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.add_guard(name, options = {})' is
          deprecated.

          Please use 'Guard.add_plugin(name, options = {})' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % "#deprecated-methods"}
        EOS

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
        GET_GUARD_CLASS = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.get_guard_class(name, fail_gracefully
          = false)' is deprecated and is now always on.

          Please use 'Guard::PluginUtil.new(name).plugin_class(fail_gracefully:
          fail_gracefully)' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % "#deprecated-methods"}
        EOS

        def get_guard_class(name, fail_gracefully = false)
          UI.deprecation(GET_GUARD_CLASS)
          PluginUtil.new(name).plugin_class(fail_gracefully: fail_gracefully)
        end

        # @deprecated Use `Guard::PluginUtil.new(name).plugin_location` instead.
        #
        # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
        #   upgrade for Guard 2.0
        #
        LOCATE_GUARD = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.locate_guard(name)' is deprecated.

          Please use 'Guard::PluginUtil.new(name).plugin_location' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % "#deprecated-methods"}
        EOS

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
        GUARD_GEM_NAMES = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.0 'Guard.guard_gem_names' is deprecated.

          Please use 'Guard::PluginUtil.plugin_names' instead.

        #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % "#deprecated-methods"}
        EOS

        def guard_gem_names
          UI.deprecation(GUARD_GEM_NAMES)
          PluginUtil.plugin_names
        end

        RUNNING = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.7.1 it was discovered that Guard.running was
          never initialized or used internally.
        EOS

        def running
          UI.deprecation(RUNNING)
          nil
        end

        LOCK = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.7.1 it was discovered that this accessor was
          never initialized or used internally.
        EOS
        def lock
          UI.deprecation(LOCK)
        end

        EVALUATOR = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        EOS

        def evaluator
          UI.deprecation(EVALUATOR)
          options = ::Guard.state.session.evaluator_options
          ::Guard::Guardfile::Evaluator.new(options)
        end

        RESET_EVALUATOR = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        EOS

        def reset_evaluator(_options)
          UI.deprecation(RESET_EVALUATOR)
        end

        RUNNER = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        EOS

        def runner
          UI.deprecation(RUNNER)
          ::Guard::Runner.new
        end

        EVALUATE_GUARDFILE = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.8.2 this method shouldn't be used
        EOS

        def evaluate_guardfile
          UI.deprecation(EVALUATE_GUARDFILE)
          options = ::Guard.state.session.evaluator_options
          evaluator = ::Guard::Guardfile::Evaluator.new(options)
          evaluator.evaluate
          msg = "No plugins found in Guardfile, please add at least one."
          ::Guard::UI.error msg if _pluginless_guardfile?
        end

        OPTIONS = <<-EOS.gsub(/^\s*/, "")
          Starting with Guard 2.9.0 Guard.options is deprecated and ideally you
          should be able to set specific options through an API or a DSL
          method. Feel free to add feature requests if there's something
          missing.
        EOS

        def options
          UI.deprecation(OPTIONS)
          ::Guard.state.session.options
        end
      end
    end
  end
end
