module Guard

  class Plugin

    # Guard has a hook mechanism that allows you to insert callbacks for
    # individual Guard plugins.
    # By default, each of the Guard plugin instance methods has a "_begin" and
    # an "_end" hook.
    # For example, the Guard::Plugin#start method has a :start_begin hook that
    # is runs immediately before Guard::Plugin#start, and a :start_end hook
    # that runs immediately after Guard::Plugin#start.
    #
    # Read more about [hooks and callbacks on the
    # wiki](https://github.com/guard/guard/wiki/Hooks-and-callbacks).
    #
    module Hooker

      require 'guard/ui'

      # Get all callbacks registered for all Guard plugins present in the
      # Guardfile.
      #
      def self.callbacks
        @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
      end

      # Add a callback.
      #
      # @param [Block] listener the listener to notify
      # @param [Guard::Plugin] guard_plugin the Guard plugin to add the callback
      # @param [Array<Symbol>] events the events to register
      #
      def self.add_callback(listener, guard_plugin, events)
        Array(events).each do |event|
          callbacks[[guard_plugin, event]] << listener
        end
      end

      # Notify a callback.
      #
      # @param [Guard::Plugin] guard_plugin the Guard plugin to add the callback
      # @param [Symbol] event the event to trigger
      # @param [Array] args the arguments for the listener
      #
      def self.notify(guard_plugin, event, *args)
        callbacks[[guard_plugin, event]].each do |listener|
          listener.call(guard_plugin, event, *args)
        end
      end

      # Reset all callbacks.
      #
      def self.reset_callbacks!
        @callbacks = nil
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
      # Here, when {Guard::Plugin::Base#run_all} is called, {#hook} will notify
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
      # When {Guard::Plugin::Base#run_all} is called, {#hook} will notify
      # callbacks registered for the "foo_bar" event.
      #
      # @param [Symbol, String] event the name of the Guard event
      # @param [Array] args the parameters are passed as is to the callbacks
      #   registered for the given event.
      #
      def hook(event, *args)
        hook_name = if event.is_a? Symbol
                      calling_method = caller[0][/`([^']*)'/, 1]
                      "#{ calling_method }_#{ event }"
                    else
                      event
                    end

        ::Guard::UI.debug "Hook :#{ hook_name } executed for #{ self.class }"

        Hooker.notify(self, hook_name.to_sym, *args)
      end

      private

      # Add all the Guard::Plugin's callbacks to the global @callbacks array
      # that's used by Guard to know which callbacks to notify.
      #
      def _register_callbacks
        callbacks.each do |callback|
          Hooker.add_callback(callback[:listener], self, callback[:events])
        end
      end

    end
  end
end
