module Guard
  module Internals
    class Queue
      attr_reader :engine

      def initialize(engine:)
        @engine = engine
        @queue = ::Queue.new
      end

      # Process the change queue, running tasks within the main Guard thread
      def process
        actions = []
        changes = { modified: [], added: [], removed: [] }

        while pending?
          if (item = @queue.pop).first.is_a?(Symbol)
            actions << item
          else
            item.each { |key, value| changes[key] += value }
          end
        end

        _run_actions(actions)
        return if changes.values.all?(&:empty?)
        Runner.new(engine: engine).run_on_changes(*changes.values)
      end

      def pending?
        !@queue.empty?
      end

      def <<(changes)
        @queue << changes
      end

      private

      def _run_actions(actions)
        actions.each do |action_args|
          args = action_args.dup
          namespaced_action = args.shift
          action = namespaced_action.to_s.sub(/^guard_/, "")
          if engine.respond_to?(action)
            engine.send(action, *args)
          else
            fail "Unknown action: #{action.inspect}"
          end
        end
      end
    end
  end
end
