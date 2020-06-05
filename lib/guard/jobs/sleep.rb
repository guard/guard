# frozen_string_literal: true

require "guard/jobs/base"
require "guard/ui"

module Guard
  module Jobs
    class Sleep < Base
      def foreground
        UI.debug "Guards jobs done. Sleeping..."
        sleep
        UI.debug "Sleep interrupted by events."
        :continue
      rescue Interrupt
        UI.debug "Sleep interrupted by user."
        :exit
      end

      def background
        Thread.main.wakeup
      end

      def handle_interrupt
        Thread.main.raise Interrupt
      end
    end
  end
end
