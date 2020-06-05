# frozen_string_literal: true

require "forwardable"

module Guard
  module Internals
    class Queue
      extend Forwardable

      delegate :<< => :queue

      def initialize(engine, runner)
        @engine = engine
        @runner = runner
        @queue = ::Queue.new
      end

      # Process the change queue, running tasks within the main Guard thread
      def process
        actions = []
        changes = { modified: [], added: [], removed: [] }

        while pending?
          if (item = queue.pop).first.is_a?(Symbol)
            actions << item
          else
            item.each { |key, value| changes[key] += value }
          end
        end

        _run_actions(actions)
        return if changes.values.all?(&:empty?)

        runner.run_on_changes(*changes.values)
      end

      def pending?
        !queue.empty?
      end

      private

      attr_reader :engine, :runner, :queue

      def _run_actions(actions)
        actions.each do |action_args|
          args = action_args.dup
          namespaced_action = args.shift
          action = namespaced_action.to_s.sub(/^guard_/, "")
          engine.send(action, *args)
        end
      end
    end
  end
end
