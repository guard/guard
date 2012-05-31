module Guard

  # The runner is responsible for running all methods defined on each guards.
  #
  class Runner

    # Deprecation message for the `run_on_change` method
    RUN_ON_CHANGE_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard v1.1 the use of the 'run_on_change' method in the '%s' guard is deprecated.

      Please consider replacing that method-call with 'run_on_changes' if the type of change
      is not important for your usecase or using either 'run_on_modifications' or 'run_on_additions'
      based on the type of the changes you want to handle.

      For more information on how to update existing guards, please head over to:
      https://github.com/guard/guard/wiki/Upgrade-guide-for-existing-guards-to-Guard-v1.1
    EOS

    # Deprecation message for the `run_on_deletion` method
    RUN_ON_DELETION_DEPRECATION = <<-EOS.gsub(/^\s*/, '')
      Starting with Guard v1.1 the use of the 'run_on_deletion' method in the '%s' guard is deprecated.

      Please consider replacing that method-call with 'run_on_removals' for future proofing your code.

      For more information on how to update existing guards, please head over to:
      https://github.com/guard/guard/wiki/Upgrade-guide-for-existing-guards-to-Guard-v1.1
    EOS

    # Displays a warning for each deprecated-method used is any registered guard.
    #
    def deprecation_warning
      ::Guard.guards.each do |guard|
        UI.deprecation(RUN_ON_CHANGE_DEPRECATION % guard.class.name)   if guard.respond_to?(:run_on_change)
        UI.deprecation(RUN_ON_DELETION_DEPRECATION % guard.class.name) if guard.respond_to?(:run_on_deletion)
      end
    end

    # Runs a Guard-task on all registered guards.
    #
    # @param [Symbol] task the task to run
    # @param [Hash] scope either the guard or the group to run the task on
    #
    # @see self.run_supervised_task
    #
    def run(task, scopes = {})
      scoped_guards(scopes) do |guard|
        run_supervised_task(guard, task)
      end
    end

    MODIFICATION_TASKS = [:run_on_modifications, :run_on_changes, :run_on_change]
    ADDITION_TASKS     = [:run_on_additions, :run_on_changes, :run_on_change]
    REMOVAL_TASKS      = [:run_on_removals, :run_on_changes, :run_on_deletion]

    # Runs the appropriate tasks on all registered guards
    # based on the passed changes.
    #
    # @param [Array<String>] modified the modified paths.
    # @param [Array<String>] added the added paths.
    # @param [Array<String>] removed the removed paths.
    #
    def run_on_changes(modified, added, removed)
      scoped_guards do |guard|
        modified_paths = Watcher.match_files(guard, modified)
        added_paths    = Watcher.match_files(guard, added)
        removed_paths  = Watcher.match_files(guard, removed)

        UI.clear if clearable?(guard, modified_paths, added_paths, removed_paths)

        run_first_task_found(guard, MODIFICATION_TASKS, modified_paths) unless modified_paths.empty?
        run_first_task_found(guard, ADDITION_TASKS, added_paths) unless added_paths.empty?
        run_first_task_found(guard, REMOVAL_TASKS, removed_paths) unless removed_paths.empty?
      end
    end

    # Run a Guard task, but remove the Guard when his work leads to a system failure.
    #
    # When the Group has `:halt_on_fail` disabled, we've to catch `:task_has_failed`
    # here in order to avoid an uncaught throw error.
    #
    # @param [Guard::Guard] guard the Guard to execute
    # @param [Symbol] task the task to run
    # @param [Array] args the arguments for the task
    # @raise [:task_has_failed] when task has failed
    #
    def run_supervised_task(guard, task, *args)
      ::Guard.within_preserved_state do
        begin
          catch Runner.stopping_symbol_for(guard) do
            guard.hook("#{ task }_begin", *args)
            result = guard.send(task, *args)
            guard.hook("#{ task }_end", result)
            result
          end

        rescue NoMethodError
          # Do nothing
        rescue Exception => ex
          UI.error("#{ guard.class.name } failed to achieve its <#{ task.to_s }>, exception was:" +
                   "\n#{ ex.class }: #{ ex.message }\n#{ ex.backtrace.join("\n") }")

          ::Guard.guards.delete guard
          UI.info("\n#{ guard.class.name } has just been fired")

          ex
        end
      end
    end

    # Returns the symbol that has to be caught when running a supervised task.
    #
    # @note If a Guard group is being run and it has the `:halt_on_fail`
    #   option set, this method returns :no_catch as it will be caught at the
    #   group level.
    # @see .scoped_guards
    #
    # @param [Guard::Guard] guard the Guard to execute
    #
    # @return [Symbol] the symbol to catch
    #
    def self.stopping_symbol_for(guard)
      return :task_has_failed if guard.group.class != Symbol

      group = ::Guard.groups(guard.group)
      group.options[:halt_on_fail] ? :no_catch : :task_has_failed
    end

  private

    # Tries to run the first implemented task by a given guard
    # from a collection of tasks.
    #
    # @param [Guard::Guard] guard the guard to run the found task on
    # @param [Array<Symbol>] tasks the tasks to run the first among
    # @param [Object] task_param the param to pass to each task
    #
    def run_first_task_found(guard, tasks, task_param)
      tasks.each do |task|
        if guard.respond_to?(task)
          run_supervised_task(guard, task, task_param)
          break
        else
          UI.debug "Trying to run #{ guard.class.name }##{ task.to_s } with #{ task_param.inspect }"
        end
      end
    end

    # Loop through all groups and run the given task for each Guard.
    #
    # Stop the task run for the all Guards within a group if one Guard
    # throws `:task_has_failed`.
    #
    # @param [Hash] scope an hash with a guard or a group scope
    # @yield the task to run
    #
    def scoped_guards(scopes = {})
      if guard = scopes[:guard]
        yield(guard)
      else
        groups = scopes[:group] ? [scopes[:group]] : ::Guard.groups
        groups.each do |group|
          catch :task_has_failed do
            ::Guard.guards(:group => group.name).each do |guard|
              yield(guard)
            end
          end
        end
      end
    end

    # Logic to know if the UI can be cleared or not in the run_on_changes method
    # based on the guard and the changes.
    #
    # @param [Guard::Guard] guard the guard where run_on_changes is called
    # @param [Array<String>] modified_paths the modified paths.
    # @param [Array<String>] added_paths the added paths.
    # @param [Array<String>] removed_paths the removed paths.
    #
    def clearable?(guard, modified_paths, added_paths, removed_paths)
      (MODIFICATION_TASKS.any? { |task| guard.respond_to?(task) } && !modified_paths.empty?) ||
      (ADDITION_TASKS.any? { |task| guard.respond_to?(task) } && !added_paths.empty?) ||
      (REMOVAL_TASKS.any? { |task| guard.respond_to?(task) } && !removed_paths.empty?)
    end

  end
end
