module Guard

  # @deprecated Inheriting from Guard::Guard is deprecated, please inherit from
  #   Guard::Plugin instead. Please note that the constructor signature has
  #   changed from Guard::Guard#initialize(watchers = [], options = {}) to
  #   Guard::Plugin#initialize(options = {}).
  #
  class Guard
    require 'guard/plugin/base'
    include ::Guard::Plugin::Base

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even if they are not in an active group!
    #
    # @param [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @param [Hash] options the custom Guard plugin options
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(watchers = [], options = {})
      ::Guard::UI.deprecation(::Guard::Deprecator::GUARD_GUARD_DEPRECATION % self.to_s)

      set_instance_variables_from_options(options.merge(:watchers => watchers))
      register_callbacks
    end

  end
end
