module Guard
  module Hook
    def self.included(base)
      base.send :include, InstanceMethods
    end

    module InstanceMethods
      # When passed a sybmol, #hook will generate a hook name
      # from the symbol and calling method name. When passed
      # a string, #hook will turn the string into a symbol
      # directly.
      def hook(event)
        hook_name = if event.is_a? Symbol
          calling_method = caller[0][/`([^']*)'/, 1]
          "#{calling_method}_#{event}".to_sym
        else
          event.to_sym
        end

        UI.info "\nHook :#{hook_name} executed for #{self.class}"
        Hook.notify(self.class, hook_name)
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

      def notify(guard_class, event)
        callbacks[[guard_class, event]].each do |listener|
          listener.call(guard_class, event)
        end
      end

      def reset_callbacks!
        @callbacks = nil
      end
    end
  end
end
