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
  class Guard
    require 'guard/hook'
    require 'guard/ui'

    include ::Guard::Hook

    attr_accessor :watchers, :options, :group

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even if they are not in an active group!
    #
    # @param [Array<Guard::Watcher>] watchers the Guard plugin file watchers
    # @param [Hash] options the custom Guard plugin options
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from a watcher
    #
    def initialize(watchers = [], options = {})
      @group = options[:group] ? options.delete(:group).to_sym : :default
      @watchers, @options = watchers, options
    end

    # Specify the source for the Guardfile template.
    # Each Guard plugin can redefine this method to add its own logic.
    #
    # @param [String] The plugin name
    #
    def self.template(name)
      File.read("#{ ::Guard.locate_guard(name) }/lib/guard/#{ name }/templates/Guardfile")
    end

    # Initialize the Guard plugin. This will copy the Guardfile template inside the Guard plugin Gem.
    # The template Guardfile must be located within the Gem at `lib/guard/guard-name/templates/Guardfile`.
    #
    # @param [String] name the name of the Guard plugin
    #
    def self.init(name)
      if ::Guard::Dsl.guardfile_include?(name)
        ::Guard::UI.info "Guardfile already includes #{ name } guard"
      else
        content = File.read('Guardfile')
        guard = template(name)

        File.open('Guardfile', 'wb') do |f|
          f.puts(content)
          f.puts("")
          f.puts(guard)
        end

        ::Guard::UI.info "#{ name } guard added to Guardfile, feel free to edit it"
      end
    end

    # Called once when Guard starts. Please override initialize method to init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    # @!method start

    # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard quits).
    #
    # @raise [:task_has_failed] when stop has failed
    # @return [Object] the task result
    #
    # @!method stop

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    #
    # @raise [:task_has_failed] when reload has failed
    # @return [Object] the task result
    #
    # @!method  reload

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    # @!method run_all

    # Default behaviour on file(s) changes that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_changes has failed
    # @return [Object] the task result
    #
    # @!method run_on_changes(paths)

    # Called on file(s) additions that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_additions has failed
    # @return [Object] the task result
    #
    # @!method run_on_additions(paths)

    # Called on file(s) modifications that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_modifications has failed
    # @return [Object] the task result
    #
    # @!method run_on_modifications(paths)

    # Called on file(s) removals that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_removals has failed
    # @return [Object] the task result
    #
    # @!method run_on_removals(paths)

    # Convert plugin to string representation. The
    # default just uses the plugin class name and
    # removes the Guard module name.
    #
    # @return [String] the string representation
    #
    def to_s
      self.class.to_s.downcase.sub('guard::', '').capitalize
    end

  end

end
