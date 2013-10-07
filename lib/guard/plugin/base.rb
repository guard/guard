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

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Returns the non-namespaced class name of the plugin
        #
        #
        # @example Non-namespaced class name for Guard::RSpec
        #   Guard::RSpec.non_namespaced_classname
        #   #=> "RSpec"
        #
        # @return [String]
        #
        def non_namespaced_classname
          self.to_s.sub('Guard::', '')
        end

        # Returns the non-namespaced name of the plugin
        #
        #
        # @example Non-namespaced name for Guard::RSpec
        #   Guard::RSpec.non_namespaced_name
        #   #=> "rspec"
        #
        # @return [String]
        #
        def non_namespaced_name
          non_namespaced_classname.downcase
        end

        # Specify the source for the Guardfile template.
        # Each Guard plugin can redefine this method to add its own logic.
        #
        # @param [String] plugin_location the plugin location
        #
        def template(plugin_location)
          File.read("#{ plugin_location }/lib/guard/#{ non_namespaced_name }/templates/Guardfile")
        end
      end

      # Called once when Guard starts. Please override initialize method to
      # init stuff.
      #
      # @raise [:task_has_failed] when start has failed
      # @return [Object] the task result
      #
      # @!method start

      # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard
      # quits).
      #
      # @raise [:task_has_failed] when stop has failed
      # @return [Object] the task result
      #
      # @!method stop

      # Called when `reload|r|z + enter` is pressed.
      # This method should be mainly used for "reload" (really!) actions like
      # reloading passenger/spork/bundler/...
      #
      # @raise [:task_has_failed] when reload has failed
      # @return [Object] the task result
      #
      # @!method reload

      # Called when just `enter` is pressed
      # This method should be principally used for long action like running all
      # specs/tests/...
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
      # @example Name for Guard::RSpec
      #   Guard::RSpec.new.name
      #   #=> "rspec"
      #
      # @return [String]
      #
      def name
        @name ||= self.class.non_namespaced_name
      end

      # Returns the plugin's class name without the Guard:: namespace.
      #
      # @example Title for Guard::RSpec
      #   Guard::RSpec.new.title
      #   #=> "RSpec"
      #
      # @return [String]
      #
      def title
        @title ||= self.class.non_namespaced_classname
      end

      # String representation of the plugin.
      #
      # @example String representation of an instance of the Guard::RSpec plugin
      #   Guard::RSpec.new.title
      #   #=> "#<Guard::RSpec @name=rspec @group=#<Guard::Group @name=default @options={}> @watchers=[] @callbacks=[] @options={all_after_pass: true}>"
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
      def _set_instance_variables_from_options(options)
        group_name = options.delete(:group) { :default }
        @group = ::Guard.add_group(group_name)
        @watchers  = options.delete(:watchers) { [] }
        @callbacks = options.delete(:callbacks) { [] }
        @options   = options
      end

    end
  end
end
