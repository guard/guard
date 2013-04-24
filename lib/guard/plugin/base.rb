module Guard

  class Plugin

    # Colection of shared methods between `Guard::Guard` (deprecated)
    # and `Guard::Plugin`.
    #
    module Base
      require 'guard/ui'
      require 'guard/plugin/hooker'

      include ::Guard::Plugin::Hooker

      attr_accessor :group, :watchers, :callbacks, :options

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

      # Returns the plugin's name (without "guard-").
      #
      # @return [String] the string representation
      #
      def name
        @name ||= self.class.to_s.downcase.sub('guard::', '')
      end

      # Returns the plugin's name capitalized.
      #
      # @return [String] the string representation
      #
      def title
        @title ||= name.capitalize
      end

      # Convert plugin to string representation.
      #
      # @return [String] the string representation
      #
      def to_s
        "#<#{self.class} @name=#{name} @group=#{group} @watchers=#{watchers} @callbacks=#{callbacks} @options=#{options}>"
      end

      private

      # Sets the @group, @watchers, @callbacks and @options variables from the
      # given options hash.
      #
      # @param [Hash] options the Guard plugin options
      #
      # @see Guard::Plugin.initialize
      #
      def set_instance_variables_from_options(options)
        set_group_from_options(options)
        @watchers  = options.delete(:watchers) { [] }
        @callbacks = options.delete(:callbacks) { [] }
        @options   = options
      end

      def set_group_from_options(options)
        group_name = options.delete(:group) { :default }
        @group = ::Guard.groups(group_name) || ::Guard.add_group(group_name)
      end

    end
  end
end