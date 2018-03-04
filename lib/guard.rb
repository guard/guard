require "thread"
require "listen"
require "forwardable"

require "guard/config"
require "guard/engine"
require "guard/api"
require "guard/plugin"
require "guard/deprecated/guard" unless Guard::Config.new.strict?

require "guard/internals/debugging"
require "guard/internals/traps"
require "guard/internals/queue"

# TODO: remove this class altogether
require "guard/interactor"

# Guard is the main module for all Guard related modules and classes.
# Also Guard plugins should use this namespace.
module Guard
  Deprecated::Guard.add_deprecated(self) unless Config.new.strict?

  class << self
    attr_reader :engine

    # @private api

    # Backward-compatibility with the Guard singleton approach
    def state
      return unless @engine

      @engine.state
    end

    def queue
      return unless @engine

      @engine.queue
    end

    def listener
      return unless @engine

      @engine.listener
    end

    def interactor
      return unless @engine

      @engine.interactor
    end

    def start(cmdline_opts = {})
      @engine = init(cmdline_opts)
      @engine.start
    end

    def init(cmdline_opts = {})
      Engine.new(cmdline_opts: cmdline_opts)
    end
  end
end
