module Guard

  # Base class that every Guard plugin implementation must inherit from.
  #
  # Guard will trigger the `start`, `stop`, `reload`, `run_all` and `run_on_changes`
  # (`run_on_additions`, `run_on_modifications` and `run_on_removals`) task methods
  # depending on user interaction and file modification.
  #
  # `run_on_changes` could be implemented to handle all the changes task case (additions,
  # modifications, removals) in once, or each task can be implemented separately with a
  # specific behavior.
  #
  # In each of these Guard task methods you have to implement some work when you want to
  # support this kind of task. The return value of each Guard task method is not evaluated
  # by Guard, but it'll be passed to the "_end" hook for further evaluation. You can
  # throw `:task_has_failed` to indicate that your Guard plugin method was not successful,
  # and successive Guard plugin tasks will be aborted when the group has set the `:halt_on_fail`
  # option.
  #
  # @see Guard::Base
  # @see Guard::Hooker
  # @see Guard::Group
  #
  # @example Throw :task_has_failed
  #
  #   def run_all
  #     if !runner.run(['all'])
  #       throw :task_has_failed
  #     end
  #   end
  #
  # Each Guard plugin should provide a template Guardfile located within the Gem
  # at `lib/guard/guard-name/templates/Guardfile`.
  #
  # By default all watchers for a Guard plugin have to return strings of paths to the
  # Guard, but if your Guard plugin wants to allow any return value from a watcher,
  # you can set the `any_return` option to true.
  #
  # If one of those methods raise an exception other than `:task_has_failed`,
  # the Guard::GuardName instance will be removed from the active guards.
  #
  class Plugin
    require 'guard/plugin/base'
    include Base

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even if they are not in an active group!
    #
    # @param [Hash] options the Guard plugin options
    # @option options [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(options = {})
      set_instance_variables_from_options(options)
      register_callbacks
    end

  end
end
