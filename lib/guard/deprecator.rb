require 'guard/ui'

module Guard
  class Deprecator

    MORE_INFO_ON_UPGRADING_TO_GUARD_1_1 = <<-EOS.gsub(/^\s*/, '')
      For more information on how to update existing Guard plugins, please head over
      to: https://github.com/guard/guard/wiki/Upgrade-guide-for-existing-guards-to-Guard-v1.1
    EOS

    MORE_INFO_ON_UPGRADING_TO_GUARD_2 = <<-EOS.gsub(/^\s*/, '')
      For more information on how to upgrade for Guard 2.0, please head over
      to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0%s
    EOS

    ADD_GUARD_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard.add_guard(name, options = {})' is deprecated.

      Please use 'Guard.add_plugin(name, options = {})' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
    EOS

    GUARDS_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard.guards(filter)' is deprecated.

      Please use 'Guard.plugins(filter)' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
    EOS

    # Deprecator message for the `Guard.get_guard_class` method
    GET_GUARD_CLASS_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard.get_guard_class(name, fail_gracefully =
      false)' is deprecated and is now always on.

      Please use 'Guard::PluginUtil.new(name).plugin_class(fail_gracefully:
      fail_gracefully)' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
    EOS

    # Deprecator message for the `Guard.locate_guard` method
    LOCATE_GUARD_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard.locate_guard(name)' is deprecated.

      Please use 'Guard::PluginUtil.new(name).plugin_location' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
    EOS

    # Deprecator message for the `Guard.guard_gem_names` method
    GUARD_GEM_NAMES_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard.guard_gem_names' is deprecated.

      Please use 'Guard::PluginUtil.plugin_names' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods'}
    EOS

    # Deprecator message for the `Guard::Dsl.evaluate_guardfile` method
    EVALUATE_GUARDFILE_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard::Dsl.evaluate_guardfile(options)' is deprecated.

      Please use 'Guard::Guardfile::Evaluator.new(options).evaluate_guardfile' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods-1'}
    EOS

    # Deprecator message for the `Guardfile.create_guardfile` method
    CREATE_GUARDFILE_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard::Guardfile.create_guardfile(options)' is deprecated.

      Please use 'Guard::Guardfile::Generator.new(options).create_guardfile' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods-2'}
    EOS

    # Deprecator message for the `Guardfile.initialize_template` method
    INITIALIZE_TEMPLATE_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard::Guardfile.initialize_template(plugin_name)' is deprecated.

      Please use 'Guard::Guardfile::Generator.new.initialize_template(plugin_name)' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods-2'}
    EOS

    # Deprecator message for the `Guardfile.initialize_all_templates` method
    INITIALIZE_ALL_TEMPLATES_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard::Guardfile.initialize_all_templates' is deprecated.

      Please use 'Guard::Guardfile::Generator.new.initialize_all_templates' instead.

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#deprecated-methods-2'}
    EOS

    # Deprecator message for when a Guard plugin inherits from Guard::Guard
    GUARD_GUARD_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0, Guard::%s should inherit from Guard::Plugin instead of Guard::Guard.

      Please note that the constructor signature has changed from Guard::Guard#initialize(watchers = [], options = {}) to Guard::Plugin#initialize(options = {}).

      #{MORE_INFO_ON_UPGRADING_TO_GUARD_2 % '#changes-in-guardguard'}
    EOS

  end
end
