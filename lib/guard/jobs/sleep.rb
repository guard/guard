require "guard/jobs/base"

module Guard
  module Jobs
    class Sleep < Base
      def foreground
        ::Guard::UI.debug "Guards jobs done. Sleeping..."
        sleep
        ::Guard::UI.debug "Sleep interrupted by events."
        :stopped
      rescue Interrupt
        ::Guard::UI.debug "Sleep interrupted by user."
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
