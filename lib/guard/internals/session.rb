# frozen_string_literal: true

require "guard/options"
require "guard/internals/plugins"
require "guard/internals/groups"

module Guard
  # @private api
  module Internals
    # TODO: split into a commandline class and session (plugins, groups)
    # TODO: swap session and metadata
    class Session
      attr_reader :plugins, :groups

      DEFAULT_OPTIONS = {
        clear: false,
        debug: false,
        no_bundler_warning: false,

        # User defined scopes
        group: [],
        plugin: [],

        # Notifier
        notify: true,

        # Interactor
        no_interactions: false,

        # Guardfile options:
        guardfile: nil,
        inline: nil,

        # Listener options
        watchdirs: Dir.pwd,
        latency: nil,
        force_polling: false,
        wait_for_delay: nil,
        listen_on: nil
      }.freeze
      EVALUATOR_OPTIONS = %w[guardfile inline].freeze

      # Internal class to store group and plugin scopes
      ScopesHash = Struct.new(:groups, :plugins)

      def initialize(engine, new_options = {})
        @engine = engine
        @options = Options.new(new_options, DEFAULT_OPTIONS)

        @plugins = Plugins.new(engine)
        @groups = Groups.new

        @cmdline_scopes = ScopesHash.new(
          Array(options.delete(:groups)) + Array(options.delete(:group)),
          Array(options.delete(:plugins)) + Array(options.delete(:plugin))
        )
        @guardfile_scopes = ScopesHash.new([], [])
        @interactor_scopes = ScopesHash.new([], [])

        @clear = @options[:clear]
        @debug = @options[:debug]
        @watchdirs = Array(@options[:watchdirs])
        @notify = @options[:notify]
        @interactor_name = @options[:no_interactions] ? :sleep : :pry_wrapper

        @guardfile_ignore = []
        @guardfile_ignore_bang = []

        @guardfile_notifier_options = {}
      end

      def guardfile_scopes=(scope)
        opts = scope.dup

        @guardfile_scopes.groups = Array(opts.delete(:groups)) + Array(opts.delete(:group))
        @guardfile_scopes.plugins = Array(opts.delete(:plugins)) + Array(opts.delete(:plugin))

        fail "Unknown options: #{opts.inspect}" unless opts.empty?
      end

      def interactor_scopes=(scopes)
        @interactor_scopes.groups = Array(scopes[:groups])
        @interactor_scopes.plugins = Array(scopes[:plugins])
      end
      # TODO: create a EvaluatorResult class?
      attr_reader :cmdline_scopes, :guardfile_scopes, :interactor_scopes

      attr_reader :guardfile_ignore
      def guardfile_ignore=(ignores)
        @guardfile_ignore += Array(ignores).flatten
      end

      attr_reader :guardfile_ignore_bang
      def guardfile_ignore_bang=(ignores)
        @guardfile_ignore_bang = Array(ignores).flatten
      end

      def clearing(flag)
        @clear = flag
      end

      def clearing?
        @clear
      end

      alias :clear? :clearing?

      def debug?
        @debug
      end

      def watchdirs
        @watchdirs_from_guardfile ||= nil
        @watchdirs_from_guardfile || @watchdirs
      end

      # set by Dsl with :directories() command
      def watchdirs=(dirs)
        dirs = [Dir.pwd] if dirs.empty?
        @watchdirs_from_guardfile = dirs.map { |dir| File.expand_path dir }
      end

      def listener_args
        if @options[:listen_on]
          [:on, @options[:listen_on]]
        else
          listener_options = {}
          %i(latency force_polling wait_for_delay).each do |option|
            listener_options[option] = @options[option] if @options[option]
          end
          expanded_watchdirs = watchdirs.map { |dir| File.expand_path dir }
          [:to, *expanded_watchdirs, listener_options]
        end
      end

      def evaluator_options
        Options.new(options.slice(*EVALUATOR_OPTIONS))
      end

      def notify_options
        names = @guardfile_notifier_options.keys
        return { notify: false } if names.include?(:off)

        {
          notify: @options[:notify],
          notifiers: @guardfile_notifier_options
        }
      end

      def guardfile_notification=(config)
        @guardfile_notifier_options.merge!(config)
      end

      attr_reader :interactor_name, :options

      # TODO: call this from within action, not within interactor command
      def convert_scopes(entries)
        scopes = { plugins: [], groups: [] }
        unknown = []

        entries.each do |entry|
          if plugin = plugins.all(entry).first
            scopes[:plugins] << plugin
          elsif group = groups.all(entry).first
            scopes[:groups] << group
          else
            unknown << entry
          end
        end

        [scopes, unknown]
      end

      def inspect
        "#<Guard::Internals::Session:#{object_id}>"
      end

      private

      attr_reader :engine
    end
  end
end
