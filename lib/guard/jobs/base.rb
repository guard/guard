# frozen_string_literal: true

module Guard
  module Jobs
    class Base
      def initialize(engine, _options = {})
        @engine = engine
      end

      # @return [Symbol] :continue once job is finished
      # @return [Symbol] :exit to tell Guard to terminate
      def foreground; end

      def background; end

      # Signal handler calls this, so avoid actually doing
      # anything other than signaling threads
      def handle_interrupt; end

      private

      attr_reader :engine
    end
  end
end
