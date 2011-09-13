module Guard
  module Hook

    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      # When +event+ is a Symbol, #hook will generate a hook name
      # by concatenating the method name from where #hook is called
      # with the given Symbol.
      # Example:
      #   def run_all
      #     hook :foo
      #   end
      # Here, when #run_all is called, #hook will notify callbacks
      # registered for the "run_all_foo" event.
      #
      # When +event+ is a String, #hook will directly turn the String
      # into a Symbol.
      # Example:
      #   def run_all
      #     hook "foo_bar"
      #   end
      # Here, when #run_all is called, #hook will notify callbacks
      # registered for the "foo_bar" event.
      #
      # +args+ parameter is passed as is to the callbacks registered
      # for the given event.
      def hook(event, *args)
        hook_name = if event.is_a? Symbol
          calling_method = caller[0][/`([^']*)'/, 1]
          "#{calling_method}_#{event}"
        else
          event
        end.to_sym

        UI.debug "Hook :#{hook_name} executed for #{self.class}"

        Hook.notify(self.class, hook_name, *args)
      end
    end

    class << self
      def callbacks
        @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def add_callback(listener, guard_class, events)
        _events = events.is_a?(Array) ? events : [events]
        _events.each do |event|
          callbacks[[guard_class, event]] << listener
        end
      end

      def has_callback?(listener, guard_class, event)
        callbacks[[guard_class, event]].include?(listener)
      end

      def notify(guard_class, event, *args)
        callbacks[[guard_class, event]].each do |listener|
          listener.call(guard_class, event, *args)
        end
      end

      def reset_callbacks!
        @callbacks = nil
      end
    end

  end
end
