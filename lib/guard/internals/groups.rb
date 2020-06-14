# frozen_string_literal: true

require "guard/group"

module Guard
  # @private api
  module Internals
    class Groups
      DEFAULT_GROUP = :default

      def initialize
        @groups = [Group.new(DEFAULT_GROUP)]
      end

      def all(filter = nil)
        return @groups unless filter

        matcher = matcher_for(filter)
        @groups.select { |group| matcher.call(group) }
      end

      def find(filter)
        all(filter).first
      end

      def add(name, options = {})
        find(name) || Group.new(name, options).tap do |group|
          fail if name == :specs && options.empty?

          @groups << group
        end
      end

      private

      def matcher_for(filter)
        case filter
        when String, Symbol
          ->(group) { group.name == filter.to_sym }
        when Regexp
          ->(group) { group.name.to_s =~ filter }
        when Array, Set
          ->(group) { filter.map(&:to_sym).include?(group.name) }
        else
          fail "Invalid filter: #{filter.inspect}"
        end
      end
    end
  end
end
