module Guard

  # Base class that every Guard implementation must inherit from.
  #
  # Guard will trigger the `start`, `stop`, `reload`, `run_all` and `run_on_changes`
  # (`run_on_additions`, `run_on_modifications` and `run_on_removals`) task methods
  # depending on user interaction and file modification.
  #
  # `run_on_changes` could be implemented to handle all the changes task case (additions,
  # modifications, removals) in once, or each task can be implemented separatly with a
  # specific behavior.
  #
  # In each of these Guard task methods you have to implement some work when you want to
  # support this kind of task. The return value of each Guard task method is not evaluated
  # by Guard, but I'll be passed to the "_end" hook for further evaluation. You can
  # throw `:task_has_failed` to indicate that your Guard method was not successful,
  # and successive guard tasks will be aborted when the group has set the `:halt_on_fail`
  # option.
  #
  # @see Guard::Hook
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
  # Each Guard should provide a template Guardfile located within the Gem
  # at `lib/guard/guard-name/templates/Guardfile`.
  #
  # By default all watchers for a Guard are returning strings of paths to the
  # Guard, but if your Guard want to allow any return value from a watcher,
  # you can set the `any_return` option to true.
  #
  # If one of those methods raise an exception other than `:task_has_failed`,
  # the Guard::GuardName instance will be removed from the active guards.
  #
  class Guard
    include Hook

    attr_accessor :watchers, :options, :group

    # Initializes a Guard.
    #
    # @param [Array<Guard::Watcher>] watchers the Guard file watchers
    # @param [Hash] options the custom Guard options
    # @option options [Symbol] group the group this Guard belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(watchers = [], options = {})
      @group = options[:group] ? options.delete(:group).to_sym : :default
      @watchers, @options = watchers, options
    end

    # Initialize the Guard. This will copy the Guardfile template inside the Guard gem.
    # The template Guardfile must be located within the Gem at `lib/guard/guard-name/templates/Guardfile`.
    #
    # @param [String] name the name of the Guard
    #
    def self.init(name)
      if ::Guard::Dsl.guardfile_include?(name)
        ::Guard::UI.info "Guardfile already includes #{ name } guard"
      else
        content = File.read('Guardfile')
        guard   = File.read("#{ ::Guard.locate_guard(name) }/lib/guard/#{ name }/templates/Guardfile")

        File.open('Guardfile', 'wb') do |f|
          f.puts(content)
          f.puts("")
          f.puts(guard)
        end

        ::Guard::UI.info "#{ name } guard added to Guardfile, feel free to edit it"
      end
    end

    def to_s
      self.class.to_s
    end

    # Call once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    # def start
    # end

    # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard quits).
    #
    # @raise [:task_has_failed] when stop has failed
    # @return [Object] the task result
    #
    # def stop
    # end

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    #
    # @raise [:task_has_failed] when reload has failed
    # @return [Object] the task result
    #
    # def reload
    # end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    # def run_all
    # end

    # Default behaviour on file(s) changes that the Guard watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    # @return [Object] the task result
    #
    # def run_on_changes(paths)
    # end

    # Called on file(s) additions that the Guard watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    # @return [Object] the task result
    #
    # def run_on_additions(paths)
    # end

    # Called on file(s) modifications that the Guard watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    # @return [Object] the task result
    #
    # def run_on_modifications(paths)
    # end

    # Called on file(s) removals that the Guard watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_change has failed
    # @return [Object] the task result
    #
    # def run_on_removals(paths)
    # end

  end

end
