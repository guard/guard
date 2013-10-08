require 'guard/notifiers/base'

module Guard
  module Notifier

    # Writes Guard notification results to a file.
    #
    # @example Add the `:file` notifier to your `Guardfile`
    #   notification :file, path: 'tmp/guard_result'
    #
    class FileNotifier < Base

      DEFAULTS = {
        format: "%s\n%s\n%s\n"
      }

      # @param [Hash] opts some options
      # @option opts [Boolean] path the path to a file where Guard notification
      #   results will be written
      #
      def self.available?(opts = {})
        super and opts.has_key?(:path)
      end

      # Writes the notification to a file. By default it writes type, title,
      # and message separated by newlines.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [String] format printf style format for file contents
      # @option opts [String] path the path of where to write the file
      #
      def notify(message, opts = {})
        super

        if opts[:path]
          format = opts.fetch(:format, DEFAULTS[:format])

          _write(opts[:path], format % [opts[:type], opts[:title], message])
        else
          ::Guard::UI.error ':file notifier requires a :path option'
        end
      end

      private

      def _write(path, contents)
        File.write(path, contents)
      end

    end

  end
end
