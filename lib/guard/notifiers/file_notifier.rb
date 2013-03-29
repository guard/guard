module Guard
  module Notifier

    # Writes guard notification results to a file
    #
    # @example Add the `:file` notifier to your `Guardfile`
    #   notification :file, path: 'tmp/guard_result'
    #
    module FileNotifier
      extend self

      # Default options for FileNotifier
      DEFAULTS = {
        :format => "%s\n%s\n%s\n"
      }

      # Test if the file notification option is available?
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @param [Hash] options notifier options
      # @return [Boolean] the availability status
      #
      def available?(silent = false, options = {})
        options.has_key?(:path)
      end

      # Write the notification to a file. By default it writes type, title, and
      # message separated by newlines.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [String] format printf style format for file contents
      # @option options [String] path the path of where to write the file
      #
      def notify(type, title, message, image, options = { })
        if options[:path]
          format = options.fetch(:format, DEFAULTS[:format])

          write(options[:path], format % [type, title, message])
        else
          ::Guard::UI.error ':file notifier requires a :path option'
        end
      end

      private
      def write(path, contents)
        File.write(path, contents)
      end
    end

  end
end
