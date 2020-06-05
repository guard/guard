# frozen_string_literal: true

require "guard/internals/session"
require "guard/internals/scope"
require "guard/internals/debugging"

module Guard
  module Internals
    class State
      # Minimal setup for non-interactive commands (list, init, show, etc.)
      def initialize(engine, cmdline_opts = {})
        @engine = engine
        @session = Session.new(engine, cmdline_opts)
        @scope = Scope.new(engine)

        # NOTE: must be set before anything calls Guard::UI.debug
        Debugging.start if session.debug?
      end

      def inspect
        "#<Guard::Internals::State:#{object_id}>"
      end

      attr_reader :scope, :session

      private

      attr_reader :engine
    end
  end
end
