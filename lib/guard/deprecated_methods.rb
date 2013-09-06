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
      ::Guard::UI.deprecation(::Guard::Deprecator::GET_GUARD_CLASS_DEPRECATION)
      ::Guard::PluginUtil.new(name).plugin_class(fail_gracefully: fail_gracefully)
    end

    # @deprecated Use `Guard::PluginUtil.new(name).plugin_location` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    def locate_guard(name)
      ::Guard::UI.deprecation(::Guard::Deprecator::LOCATE_GUARD_DEPRECATION)
      ::Guard::PluginUtil.new(name).plugin_location
    end

    # @deprecated Use `Guard::PluginUtil.plugin_names` instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to
    #   upgrade for Guard 2.0
    #
    def guard_gem_names
      ::Guard::UI.deprecation(::Guard::Deprecator::GUARD_GEM_NAMES_DEPRECATION)
      ::Guard::PluginUtil.plugin_names
    end

  end

end
