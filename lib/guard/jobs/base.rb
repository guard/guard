# frozen_string_literal: true

module Guard
  module Jobs
    class Base
      def initialize(engine, _options = {})
        @engine = engine
        @mutex = Mutex.new
        @thread = nil
      end

      # Run in foreground and wait until interrupted or closed
      # @return [Symbol] :continue once job is finished
      # @return [Symbol] :exit to tell Guard to terminate
      def foreground
        # This waits for the foreground thread to finish (i.e. get killed in `#background`).
        _start_foreground_thread

        _cleanup_before_background unless thread&.alive?

        @mutex.synchronize { thread.stop? ? :continue : :exit }
      end

      # Remove interactor so other tasks can run in foreground
      def background
        UI.debug "Before @mutex.synchronize in #{self.class}##{__method__} (#{thread}) before kill"
        @mutex.synchronize do
          thread&.kill
        end
        UI.debug "After @mutex.synchronize in #{self.class}##{__method__} (#{thread}) after kill"
      end

      private

      attr_reader :engine, :thread

      def _start_foreground_thread
        raise NotImplementedError
      end

      def _cleanup_before_background; end
    end
  end
end
