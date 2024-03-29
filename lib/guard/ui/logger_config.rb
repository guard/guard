# frozen_string_literal: true

require "logger"
require "guard/options"

module Guard
  module UI
    # @private
    # Specific logger config.
    class LoggerConfig < Guard::Options
      DEFAULTS = {
        progname: "Guard",
        level: :info,
        template: ":time - :severity - :message",
        time_format: "%H:%M:%S",
        flush_seconds: 0,

        # Other LumberJack device-specific options
        # max_size: "5M",
        # buffer_size: 0,
        # additional_lines: nil,
      }.freeze

      def initialize(options = {})
        super(options, DEFAULTS)
      end

      def template=(value)
        self["template"] = value
      end

      def level=(value)
        self["level"] = value
      end
    end
  end
end
