# frozen_string_literal: true

require "async"
require "async/condition"
require "guard/jobs/base"
require "guard/ui"

module Guard
  module Jobs
    class Sleep < Base
      def initialize(engine, options = {})
        super
        @wake_condition = Async::Condition.new
        @exit_requested = false
      end

      def foreground
        UI.debug "Guards jobs done. Sleeping..."

        # Wait on condition - this yields the fiber
        @wake_condition.wait

        UI.debug "Sleep interrupted by events."
        @exit_requested ? :exit : :continue
      rescue Interrupt
        UI.debug "Sleep interrupted by user."
        :exit
      end

      def background
        @exit_requested = false
        @wake_condition.signal
      end

      def handle_interrupt
        @exit_requested = true
        @wake_condition.signal
      end
    end
  end
end
