require "guard/group"

require "guard/plugin_util"
require "guard/internals/session"
require "guard/internals/scope"
require "guard/runner"

module Guard
  module Internals
    class State
      # Minimal setup for non-interactive commands (list, init, show, etc.)
      def initialize(engine:, cmdline_opts:)
        @session = Session.new(engine: engine, options: cmdline_opts)
        @scope = Scope.new(session: @session)

        # NOTE: must be set before anything calls Guard::UI.debug
        Debugging.start if session.debug?
      end

      attr_reader :scope
      attr_reader :session
    end
  end
end
