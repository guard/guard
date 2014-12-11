require "guard/group"

require "guard/plugin_util"
require "guard/internals/session"
require "guard/internals/scope"
require "guard/runner"

module Guard
  module Internals
    class State
      # Minimal setup for non-interactive commands (list, init, show, etc.)
      def initialize(cmdline_opts)
        @session = Session.new(cmdline_opts)

        @scope = Scope.new

        # NOTE: must be set before anything calls Guard::UI.debug
        Debugging.start if session.debug?
      end

      attr_reader :scope
      attr_reader :session

      # @private api
      # TODO: REMOVE!
      def reset_session(&block)
        Runner.new.run(:stop)
        Notifier.disconnect
        options = @session.options.dup
        @session = Session.new(options)
        block.call
        Runner.new.run(:start)
      ensure
        Notifier.connect(session.notify_options)
      end
    end
  end
end
