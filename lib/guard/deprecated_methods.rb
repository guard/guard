module Guard
  module DeprecatedMethods
    # @deprecated Use `Guard.plugins(filter)` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    def guards(filter = nil)
      ::Guard::UI.deprecation(::Guard::Deprecator::GUARDS_DEPRECATION)
      plugins(filter)
    end

    # @deprecated Use `Guard.add_plugin(name, options = {})` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    def add_guard(*args)
      ::Guard::UI.deprecation(::Guard::Deprecator::ADD_GUARD_DEPRECATION)
      add_plugin(*args)
    end

    # @deprecated Use
    #   `Guard::PluginUtil.new(name).plugin_class(fail_gracefully:
    #   fail_gracefully)` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    def get_guard_class(name, fail_gracefully = false)
      UI.deprecation(Deprecator::GET_GUARD_CLASS_DEPRECATION)
      PluginUtil.new(name).plugin_class(fail_gracefully: fail_gracefully)
    end

    # @deprecated Use `Guard::PluginUtil.new(name).plugin_location` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    def locate_guard(name)
      UI.deprecation(Deprecator::LOCATE_GUARD_DEPRECATION)
      PluginUtil.new(name).plugin_location
    end

    # @deprecated Use `Guard::PluginUtil.plugin_names` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    def guard_gem_names
      UI.deprecation(Deprecator::GUARD_GEM_NAMES_DEPRECATION)
      PluginUtil.plugin_names
    end

    def running
      UI.deprecation(Deprecator::GUARD_RUNNING_DEPRECATION)
      nil
    end

    def lock
      UI.deprecation(Deprecator::GUARD_LOCK_DEPRECATION)
    end

    def evaluator
      UI.deprecation(Deprecator::GUARD_EVALUATOR_DEPRECATION)
      # TODO: this will be changed to the following when scope is reworked
      # ::Guard.session.evaluator
      ::Guard.instance_variable_get(:@evaluator)
    end
  end
end
