# frozen_string_literal: true

require "async"
require "async/condition"

module Guard
  module Jobs
    class Base
      def initialize(engine, _options = {})
        @engine = engine
        @condition = Async::Condition.new
      end

      # @return [Symbol] :continue once job is finished
      # @return [Symbol] :exit to tell Guard to terminate
      def foreground; end

      def background; end

      # Signal handler calls this, so avoid actually doing
      # anything other than signaling threads/fibers
      def handle_interrupt; end

      private

      attr_reader :engine, :condition
    end
  end
end
