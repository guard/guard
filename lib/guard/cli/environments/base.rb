# frozen_string_literal: true

require "guard/ui"

module Guard
  module Cli
    module Environments
      class Base
        # Initialize a new Guard::Cli::Environments::Base object.
        #
        # @option options [Boolean] no_bundler_warning whether to show the "Bundler should be used" warning or not
        #
        # @return [Guard::Cli::Environments::Base] a Guard::Cli::Environments::Base instance
        def initialize(options)
          @options = options.dup
        end

        private

        attr_reader :options

        def bundler_check
          return if options[:no_bundler_warning]
          return unless File.exist?("Gemfile")
          return if ENV["BUNDLE_GEMFILE"] || ENV["RUBYGEMS_GEMDEPS"]

          UI.info <<~BUNDLER_NOTICE

            Guard here! It looks like your project has a Gemfile, yet you are running
            `guard` outside of Bundler. If this is your intent, feel free to ignore this
            message. Otherwise, consider using `bundle exec guard` to ensure your
            dependencies are loaded correctly.
            (You can run `guard` with --no-bundler-warning to get rid of this message.)
          BUNDLER_NOTICE
        end
      end
    end
  end
end
