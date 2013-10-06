require 'guard/notifiers/base'

module Guard
  module Notifier

    # Shows system notifications in the terminal title bar.
    #
    class TerminalTitle < Base

      # Shows a system notification.
      #
      # @param [Hash] opts additional notification library options
      # @option opts [String] message the notification message body
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      #
      def notify(message, opts = {})
        super

        first_line = message.sub(/^\n/, '').sub(/\n.*/m, '')

        puts "\e]2;[#{ opts[:title] }] #{ first_line }\a"
      end

      # Clears the terminal title
      #
      def self.turn_off
        puts "\e]2;\a"
      end

    end

  end
end
