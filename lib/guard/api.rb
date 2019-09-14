# frozen_string_literal: true

require "guard/internals/groups"

module Guard
  module API
    TEMPLATE_FORMAT = "%s/lib/guard/%s/templates/Guardfile".freeze

    require "guard/ui"

    def self.included(base)
      # Don't extend modules, extend only classes
      base.extend(ClassMethods) if base.respond_to?(:superclass)
      base.class_eval do
        attr_accessor :engine, :group, :watchers, :callbacks, :options
      end
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
        to_s.sub(/\AGuard::/, "").sub(/::Plugin\z/, "")
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
        File.read(format(TEMPLATE_FORMAT, plugin_location, non_namespaced_name))
      end
    end

    # When event is a Symbol, {#hook} will generate a hook name
    # by concatenating the method name from where {#hook} is called
    # with the given Symbol.
    #
    # @example Add a hook with a Symbol
    #
    #   def run_all
    #     hook :foo
    #   end
    #
    # Here, when {Guard::Plugin#run_all} is called, {#hook} will notify
    # callbacks registered for the "run_all_foo" event.
    #
    # When event is a String, {#hook} will directly turn the String
    # into a Symbol.
    #
    # @example Add a hook with a String
    #
    #   def run_all
    #     hook "foo_bar"
    #   end
    #
    # When {Guard::Plugin::run_all} is called, {#hook} will notify
    # callbacks registered for the "foo_bar" event.
    #
    # @param [Symbol, String] event the name of the Guard event
    # @param [Array] args the parameters are passed as is to the callbacks
    #   registered for the given event.
    #
    def hook(event, *args)
      hook_name = if event.is_a? Symbol
                    calling_method = caller(1..1).first[/`([^']*)'/, 1]
                    "#{calling_method}_#{event}"
                  else
                    event
                  end

      UI.debug "Hook :#{hook_name} executed for #{self.class}"

      notify(hook_name.to_sym, *args)
    end

    # Add a callback.
    #
    # @param [Block] listener the listener to notify
    # @param [Guard::Plugin] guard_plugin the Guard plugin to add the callback
    # @param [Array<Symbol>] events the events to register
    #
    def add_callback(events, block)
      Array(events).each do |event|
        callbacks[event] << block
      end
    end

    # Notify a callback.
    #
    # @param [Guard::Plugin] guard_plugin the Guard plugin to add the callback
    # @param [Symbol] event the event to trigger
    # @param [Array] args the arguments for the listener
    #
    def notify(event, *args)
      callbacks[event].each do |block|
        block.call(self, event, *args)
      end
    end

    # Called once when Guard starts. Please override initialize method to
    # init stuff.
    #
    # @raise [:task_has_failed] when start has failed
    # @return [Object] the task result
    #
    def start; end

    # Called when `stop|quit|exit|s|q|e + enter` is pressed (when Guard
    # quits).
    #
    # @raise [:task_has_failed] when stop has failed
    # @return [Object] the task result
    #
    def stop; end

    # Called when `reload|r|z + enter` is pressed.
    # This method should be mainly used for "reload" (really!) actions like
    # reloading passenger/spork/bundler/...
    #
    # @raise [:task_has_failed] when reload has failed
    # @return [Object] the task result
    #
    def reload; end

    # Called when just `enter` is pressed
    # This method should be principally used for long action like running all
    # specs/tests/...
    #
    # @raise [:task_has_failed] when run_all has failed
    # @return [Object] the task result
    #
    def run_all; end

    # Default behaviour on file(s) changes that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_changes has failed
    # @return [Object] the task result
    #
    def run_on_changes(paths); end

    # Called on file(s) additions that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_additions has failed
    # @return [Object] the task result
    #
    def run_on_additions(paths); end

    # Called on file(s) modifications that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_modifications has failed
    # @return [Object] the task result
    #
    def run_on_modifications(paths); end

    # Called on file(s) removals that the Guard plugin watches.
    #
    # @param [Array<String>] paths the changes files or paths
    # @raise [:task_has_failed] when run_on_removals has failed
    # @return [Object] the task result
    #
    def run_on_removals(paths); end

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
    #
    #   Guard::RSpec.new.title
    #   #=> "#<Guard::RSpec @name=rspec @group=#<Guard::Group @name=default
    #   @options={}> @watchers=[] @callbacks=[] @options={all_after_pass:
    #   true}>"
    #
    # @return [String] the string representation
    #
    def to_s
      "#<#{self.class} @name=#{name} @group=#{group} @watchers=#{watchers}"\
        " @callbacks=#{callbacks} @options=#{options}>"
    end

    private

    # Initializes a Guard plugin.
    # Don't do any work here, especially as Guard plugins get initialized even
    # if they are not in an active group!
    #
    # @param [Hash] options the Guard plugin options
    # @option options [Array<Guard::Watcher>] watchers the Guard plugin file
    #   watchers
    # @option options [Symbol] group the group this Guard plugin belongs to
    # @option options [Boolean] any_return allow any object to be returned from
    #   a watcher
    #
    def initialize(engine:, options: {})
      @engine = engine
      @options = options
      _init
      _register_callbacks(options.delete(:callbacks) { [] })
    end

    def _init
      group_name = options.delete(:group) { :default }
      @group = engine.groups.add(group_name)
      @watchers = options.delete(:watchers) { [] }
      @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
    end

    # Add all the Guard::Plugin's callbacks to the global @callbacks array
    # that's used by Guard to know which callbacks to notify.
    #
    def _register_callbacks(callbacks)
      callbacks.each do |callback|
        add_callback(callback[:events], callback[:listener])
      end
    end
  end
end
