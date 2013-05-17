require 'rbconfig'
require 'guard/ui'

module Guard
  module Notifier

    # System notifications using notify-send, a binary that ships with
    # the libnotify-bin package on many Debian-based distributions.
    #
    # @example Add the `:notifysend` notifier to your `Guardfile`
    #   notification :notifysend
    #
    module NotifySend
      extend self

      # Default options for the notify-send program
      DEFAULTS = {
        :t => 3000, # Default timeout is 3000ms
        :h => 'int:transient:1' # Automatically close the notification
      }

      # Full list of options supported by notify-send
      SUPPORTED = [:u, :t, :i, :c, :h]

      # Test if the notification program is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @param [Hash] options notifier options
      # @return [Boolean] the availability status
      #
      def available?(silent = false, options = {})
        if (RbConfig::CONFIG['host_os'] =~ /linux|freebsd|openbsd|sunos|solaris/) and (not `which notify-send`.empty?)
          true
        else
          ::Guard::UI.error 'The :notifysend notifier runs only on Linux, FreeBSD, OpenBSD and Solaris with the libnotify-bin package installed.' unless silent
          false
        end
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [String] c the notification category
      # @option options [Number] t the number of milliseconds to display (1000, 3000)
      #
      def notify(type, title, message, image, options = { })
        command = [title, message]
        options = DEFAULTS.merge(options).merge({
          :i => image
        })
        options[:u] ||= notifysend_urgency(type)
        system('notify-send', *to_arguments(command, SUPPORTED, options))
      end

      private

      # Convert Guards notification type to the best matching
      # notify-send urgency.
      #
      # @param [String] type the Guard notification type
      # @return [String] the notify-send urgency
      #
      def notifysend_urgency(type)
        { 'failed' => 'normal', 'pending' => 'low' }.fetch(type, 'low')
      end

      # Build a shell command out of a command string and option hash.
      #
      # @param [String] command the command execute
      # @param [Array] supported list of supported option flags
      # @param [Hash] options additional command options
      # @return [Array<String>] the command and its options converted to a shell command.
      #
      def to_arguments(command, supported, options = {})
        options.reduce(command) do |cmd, (flag, value)|
          supported.include?(flag) ? (cmd << "-#{ flag }" << value.to_s) : cmd
        end
      end
    end
  end
end
