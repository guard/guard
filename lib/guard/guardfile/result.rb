# frozen_string_literal: true

require "guard/internals/groups"

module Guard
  module Guardfile
    # This class is responsible for storing the result of the Guardfile evaluation.
    #
    # @see Guard::Dsl
    #
    class Result
      attr_accessor :clearing

      def plugin_names
        plugins.map(&:first).map(&:to_sym)
      end

      # Store notification settings as a hash: `{ off: {} }`.
      #
      # @return [Hash]
      #
      def notification
        @notification ||= {}
      end

      # Store interactor settings as a hash: `{ off: {} }`.
      #
      # @return [Hash]
      #
      def interactor
        @interactor ||= {}
      end

      # Store groups as a hash: `{ frontend: {}, backend: {} }`.
      #
      # @return [Hash]
      #
      def groups
        @groups ||= { Guard::Internals::Groups::DEFAULT_GROUP => {} }
      end

      # Store plugins as an array of hashes: `[{ name: "", options: {} }]`.
      #
      # @return [Array<Hash>]
      #
      def plugins
        @plugins ||= []
      end

      # Store ignore regexps as an array: `[/foo/]`.
      #
      # @return [Array<Regexp>]
      #
      def ignore
        @ignore ||= []
      end

      # Store ignore! regexps as an array: `[/foo/]`.
      #
      # @return [Array<Regexp>]
      #
      def ignore_bang
        @ignore_bang ||= []
      end

      # Store logger settings as a hash: `{ off: {} }`.
      #
      # @return [Hash]
      #
      def logger
        @logger ||= {}
      end

      # Store scopes settings as a hash: `{ plugins: [:rspec] }`.
      #
      # @return [Hash]
      #
      def scopes
        @scopes ||= {}
      end

      # Store directories as an array: `['foo']`.
      #
      # @return [Array<String>]
      #
      def directories
        @directories ||= []
      end
    end
  end
end
