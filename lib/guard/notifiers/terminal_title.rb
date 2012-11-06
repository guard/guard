# Module for notifying test result to terminal title
module Guard
  module Notifier
    module TerminalTitle
      extend self

      # Test if the notification library is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @return [Boolean] the availability status
      #
      def available?(silent = false)
        true
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      #
      def notify(type, title, message, image, options = { })
        first_line = message.sub(/^\n/, '').sub(/\n.*/m, '')
        puts("\e]2;[#{ title }] #{ first_line }\a")
      end
    end
  end
end
