require "guard/ui"

require "guard/jobs/sleep"
require "guard/jobs/pry_wrapper"

module Guard
  class Interactor
    # Initializes the interactor. This configures
    # Pry and creates some custom commands and aliases
    # for Guard.
    #
    def initialize(no_interaction = false)
      @interactive = !no_interaction && self.class.enabled?

      job_klass = interactive? ? Jobs::PryWrapper : Jobs::Sleep
      @idle_job = job_klass.new(self.class.options)
    end

    def interactive?
      @interactive
    end

    # Run in foreground and wait until interrupted or closed
    def foreground
      idle_job.foreground
    end

    # Remove interactor so other tasks can run in foreground
    def background
      idle_job.background
    end

    def handle_interrupt
      idle_job.handle_interrupt
    end

    class << self
      def options
        @options ||= {}
      end

      # Pass options to interactor's job when it's created
      attr_writer :options

      # TODO: allow custom user idle jobs, e.g. [:pry, :sleep, :exit, ...]
      def enabled?
        @enabled || @enabled.nil?
      end

      alias_method :enabled, :enabled?

      # TODO: handle switching interactors during runtime?
      attr_writer :enabled

      # Converts and validates a plain text scope
      # to a valid plugin or group scope.
      #
      # @param [Array<String>] entries the text scope
      # @return [Hash, Array<String>] the plugin or group scope, the unknown
      #   entries
      #
      # TODO: call this from within action, not within interactor command
      def convert_scope(entries)
        scopes  = { plugins: [], groups: [] }
        unknown = []

        entries.each do |entry|
          if plugin = ::Guard.plugin(entry)
            scopes[:plugins] << plugin
          elsif group = ::Guard.group(entry)
            scopes[:groups] << group
          else
            unknown << entry
          end
        end

        [scopes, unknown]
      end
    end

    private

    attr_reader :idle_job
  end
end
