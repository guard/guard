module Guard

  # Guard has a hook mechanism that allows you to insert callbacks for individual Guard plugins.
  # By default, each of the Guard plugin instance methods has a "_begin" and an "_end" hook.
  # For example, the Guard::Guard#start method has a :start_begin hook that is runs immediately
  # before Guard::Guard#start, and a :start_end hook that runs immediately after Guard::Guard#start.
  #
  # Read more about [hooks and callbacks on the wiki](https://github.com/guard/guard/wiki/Hooks-and-callbacks).
  #
  module Hook

    require 'guard/ui'

    # The Hook module gets included.
    #
    # @param [Class] base the class that includes the module
    #
    def self.included(base)
      base.send :include, InstanceMethods
    end

    # Instance methods that gets included in the base class.
    #
    module InstanceMethods

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
      # Here, when {Guard::Guard#run_all} is called, {#hook} will notify callbacks
      # registered for the "run_all_foo" event.
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
      # When {Guard::Guard#run_all} is called, {#hook} will notify callbacks
      # registered for the "foo_bar" event.
      #
      # @param [Symbol, String] event the name of the Guard event
      # @param [Array] args the parameters are passed as is to the callbacks registered for the given event.
      #
      def hook(event, *args)
        hook_name = if event.is_a? Symbol
                      calling_method = caller[0][/`([^']*)'/, 1]
                      "#{ calling_method }_#{ event }"
                    else
                      event
                    end.to_sym

        ::Guard::UI.debug "Hook :#{ hook_name } executed for #{ self.class }"

        Hook.notify(self.class, hook_name, *args)
      end
    end

    class << self

      # Get all callbacks.
      #
      def callbacks
        @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
      end

      # Add a callback.
      #
      # @param [Block] listener the listener to notify
      # @param [Guard::Guard] guard_class the Guard class to add the callback
      # @param [Array<Symbol>] events the events to register
      #
      def add_callback(listener, guard_class, events)
        _events = events.is_a?(Array) ? events : [events]
        _events.each do |event|
          callbacks[[guard_class, event]] << listener
        end
      end

      # Checks if a callback has been registered.
      #
      # @param [Block] listener the listener to notify
      # @param [Guard::Guard] guard_class the Guard class to add the callback
      # @param [Symbol] event the event to look for
      #
      def has_callback?(listener, guard_class, event)
        callbacks[[guard_class, event]].include?(listener)
      end

      # Notify a callback.
      #
      # @param [Guard::Guard] guard_class the Guard class to add the callback
      # @param [Symbol] event the event to trigger
      # @param [Array] args the arguments for the listener
      #
      def notify(guard_class, event, *args)
        callbacks[[guard_class, event]].each do |listener|
          listener.call(guard_class, event, *args)
        end
      end

      # Reset all callbacks.
      #
      def reset_callbacks!
        @callbacks = nil
      end

    end

  end
end
