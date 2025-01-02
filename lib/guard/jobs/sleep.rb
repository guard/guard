# frozen_string_literal: true

require "guard/jobs/base"
require "guard/ui"

module Guard
  module Jobs
    class Sleep < Base
      private

      def _start_foreground_thread
        UI.debug "Guards jobs done. Sleeping..."
        @mutex.synchronize do
          break thread if thread&.alive?

          @thread = Thread.new { sleep }
        end&.join
      end
    end
  end
end
