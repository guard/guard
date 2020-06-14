# frozen_string_literal: true

require "guard/internals/session"
require "guard/internals/debugging"

module Guard
  module Internals
    class State
      # Minimal setup for non-interactive commands (list, init, show, etc.)
      def initialize(engine, cmdline_opts = {})
        @engine = engine
        @cmdline_opts = cmdline_opts

        # NOTE: must be set before anything calls Guard::UI.debug
        Debugging.start if session.debug?
      end

      def session
        @session ||= Session.new(engine.evaluator, cmdline_opts)
      end

      def inspect
        "#<Guard::Internals::State:#{object_id}>"
      end

      private

      attr_reader :cmdline_opts, :engine
    end
  end
end
