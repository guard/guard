# frozen_string_literal: true

require "async"
require "async/queue"
require "async/condition"

module Guard
  module Internals
    class Queue
      def initialize(engine, runner)
        @engine = engine
        @runner = runner
        @queue = Async::Queue.new
        @condition = Async::Condition.new
        @mutex = Mutex.new
      end

      # Push changes to queue (called from Listen callback or signal handlers)
      # Thread-safe: can be called from Listen's thread
      def <<(changes)
        @queue.enqueue(changes)
        # Signal from any thread safely
        @mutex.synchronize do
          @condition.signal
        rescue nil
        end
      end

      # Process the change queue, running tasks within the main Guard fiber
      def process
        actions = []
        changes = { modified: [], added: [], removed: [] }

        while pending?
          item = dequeue_nonblocking
          break unless item

          if item.first.is_a?(Symbol)
            actions << item
          else
            item.each { |key, value| changes[key] += value }
          end
        end

        _run_actions(actions)
        return if changes.values.all?(&:empty?)

        @runner.run_on_changes(*changes.values)
      end

      def pending?
        !@queue.empty?
      end

      # Wait for items to be available (fiber-yielding)
      def wait
        @condition.wait unless pending?
      end

      private

      def dequeue_nonblocking
        return nil if @queue.empty?

        @queue.dequeue
      end

      def _run_actions(actions)
        actions.each do |action_args|
          args = action_args.dup
          action = args.shift
          @engine.public_send(action, *args)
        end
      end
    end
  end
end
