module Guard
  module Jobs
    class Base
      def initialize(_options)
      end

      # @return [Symbol] :stopped once job is finished
      # @return [Symbol] :exit to tell Guard to terminate
      def foreground
      end

      def background
      end

      # Signal handler calls this, so avoid actually doing
      # anything other than signaling threads
      def handle_interrupt
      end

      # Kill the job and cleanup for an exit
      def destroy
      end
    end
  end
end
