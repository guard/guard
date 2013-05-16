module Guard
  class Deprecator

    require 'guard/ui'

    # Deprecator message for the `watch_all_modifications` start option
    GET_GUARD_CLASS_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0 'Guard.get_guard_class(name, fail_gracefully =
      false)' is deprecated and is now always on.

      Please use 'Guard::PluginUtil.new(name).plugin_class(:fail_gracefully =>
      fail_gracefully)' instead.

      For more information on how to upgrade for Guard 2.0, please head over to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0
    EOS

    # Deprecator message for when a Guard plugin inherits from Guard::Guard
    GUARD_GUARD_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 2.0, Guard::%s should inherit from Guard::Plugin instead of Guard::Guard.

      Please not that the constructor signature has changed from Guard::Guard#initialize(watchers = [], options = {}) to Guard::Plugin#initialize(options = {}).

      For more information on how to upgrade for Guard 2.0, please head over to: https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0
    EOS

    # Deprecator message for the `watch_all_modifications` start option
    WATCH_ALL_MODIFICATIONS_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 1.1 the 'watch_all_modifications' option is removed
      and is now always on.
    EOS

    # Deprecator message for the `no_vendor` start option
    NO_VENDOR_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 1.1 the 'no_vendor' option is removed because the
      monitoring gems are now part of a new gem called Listen.
      (https://github.com/guard/listen)

      You can specify a custom version of any monitoring gem directly in your
      Gemfile if you want to overwrite Listen's default monitoring gems.
    EOS

    # Deprecator message for the `run_on_change` method
    RUN_ON_CHANGE_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 1.1 the use of the 'run_on_change' method in the '%s' guard is deprecated.

      Please consider replacing that method-call with 'run_on_changes' if the type of change
      is not important for your usecase or using either 'run_on_modifications' or 'run_on_additions'
      based on the type of the changes you want to handle.

      For more information on how to update existing guards, please head over to:
      https://github.com/guard/guard/wiki/Upgrade-guide-for-existing-guards-to-Guard-v1.1
    EOS

    # Deprecator message for the `run_on_deletion` method
    RUN_ON_DELETION_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 1.1 the use of the 'run_on_deletion' method in the '%s' guard is deprecated.

      Please consider replacing that method-call with 'run_on_removals' for future proofing your code.

      For more information on how to update existing guards, please head over to:
      https://github.com/guard/guard/wiki/Upgrade-guide-for-existing-guards-to-Guard-v1.1
    EOS

    # Deprecator message for the `interactor` method
    DSL_METHOD_INTERACTOR_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 1.4 the use of the 'interactor' Guardfile DSL method is only used to
      disable or pass options to the Pry interactor. All other usages are deprecated.
    EOS

    # Deprecator message for the `ignore_paths` method
    DSL_METHOD_IGNORE_PATHS_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard 1.1 the use of the 'ignore_paths' Guardfile DSL method is deprecated.

      Please replace that method with the better 'ignore' or/and 'filter' methods.
      Documentation on the README: https://github.com/guard/guard#ignore
    EOS

    class << self

      # Displays a warning for each deprecated options used.
      #
      def deprecated_options_warning(options)
        ::Guard::UI.deprecation(WATCH_ALL_MODIFICATIONS_DEPRECATION) if options[:watch_all_modifications]
        ::Guard::UI.deprecation(NO_VENDOR_DEPRECATION) if options[:no_vendor]
      end

      # Displays a warning for each deprecated-method used is any registered guard.
      #
      def deprecated_plugin_methods_warning
        ::Guard.guards.each do |guard|
          ::Guard::UI.deprecation(RUN_ON_CHANGE_DEPRECATION % guard.class.name)   if guard.respond_to?(:run_on_change)
          ::Guard::UI.deprecation(RUN_ON_DELETION_DEPRECATION % guard.class.name) if guard.respond_to?(:run_on_deletion)
        end
      end

    end

  end
end