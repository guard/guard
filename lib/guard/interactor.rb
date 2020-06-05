# frozen_string_literal: true

require "forwardable"
require "guard/jobs/pry_wrapper"
require "guard/jobs/sleep"

module Guard
  # @private
  class Interactor
    attr_reader :interactive

    # Initializes the interactor. This configures
    # Pry and creates some custom commands and aliases
    # for Guard.
    #
    def initialize(engine, interactive = true)
      @engine = engine
      @interactive = interactive
    end
    alias_method :interactive?, :interactive

    def options
      @options ||= {}
    end

    def options=(opts)
      @options = opts

      _reset
    end

    def interactive=(flag)
      @interactive = flag

      _reset
    end

    def background
      return unless _idle_job?

      _idle_job.background
    end

    extend Forwardable
    delegate %i(foreground handle_interrupt) => :_idle_job

    private

    attr_reader :engine

    def _job_klass
      if interactive
        Jobs::PryWrapper
      else
        Jobs::Sleep
      end
    end

    def _idle_job
      @_idle_job ||= _job_klass.new(engine, options)
    end

    def _idle_job?
      !!@_idle_job
    end

    def _reset
      return unless _idle_job?

      background
      @_idle_job = nil
    end
  end
end
