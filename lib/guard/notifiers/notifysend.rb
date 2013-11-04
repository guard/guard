require 'guard/notifiers/base'

module Guard
  module Notifier

    # System notifications using notify-send, a binary that ships with
    # the libnotify-bin package on many Debian-based distributions.
    #
    # @example Add the `:notifysend` notifier to your `Guardfile`
    #   notification :notifysend
    #
    class NotifySend < Base

      # Default options for the notify-send notifications.
      DEFAULTS = {
        t: 3000, # Default timeout is 3000ms
        h: 'int:transient:1' # Automatically close the notification
      }

      # Full list of options supported by notify-send.
      SUPPORTED = [:u, :t, :i, :c, :h]

      def self.supported_hosts
        %w[linux freebsd openbsd sunos solaris]
      end

      def self.available?(opts = {})
        super and _register!(opts)
      end

      # @private
      #
      # @return [Boolean] whether or not the notify-send binary is available
      #
      def self._notifysend_binary_available?
        !`which notify-send`.empty?
      end

      # @private
      #
      # Detects if the notify-send binary is available and if not, displays an
      # error message unless `opts[:silent]` is true.
      #
      # @return [Boolean] whether or not the notify-send binary is available
      #
      def self._register!(opts)
        if _notifysend_binary_available?
          true
        else
          unless opts[:silent]
            ::Guard::UI.error 'The :notifysend notifier runs only on Linux, FreeBSD, OpenBSD and Solaris with the libnotify-bin package installed.'
          end
          false
        end
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [String] c the notification category
      # @option opts [Number] t the number of milliseconds to display (1000,
      #   3000)
      #
      def notify(message, opts = {})
        super

        command = [opts[:title], message]
        opts = DEFAULTS.merge(
          i: opts.delete(:image),
          u: _notifysend_urgency(opts.delete(:type))
        ).merge(opts)

        system('notify-send', *_to_arguments(command, SUPPORTED, opts))
      end

      private

      # Converts Guards notification type to the best matching
      # notify-send urgency.
      #
      # @param [String] type the Guard notification type
      # @return [String] the notify-send urgency
      #
      def _notifysend_urgency(type)
        { 'failed' => 'normal', 'pending' => 'low' }.fetch(type, 'low')
      end

      # Builds a shell command out of a command string and option hash.
      #
      # @param [String] command the command execute
      # @param [Array] supported list of supported option flags
      # @param [Hash] opts additional command options
      # @return [Array<String>] the command and its options converted to a shell command.
      #
      def _to_arguments(command, supported, opts = {})
        opts.reduce(command) do |cmd, (flag, value)|
          supported.include?(flag) ? (cmd << "-#{ flag }" << value.to_s) : cmd
        end
      end

    end

  end
end
