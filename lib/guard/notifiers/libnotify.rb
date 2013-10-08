require 'guard/notifiers/base'

module Guard
  module Notifier

    # System notifications using the
    # [libnotify](https://github.com/splattael/libnotify) gem.
    #
    # This gem is available for Linux, FreeBSD, OpenBSD and Solaris and sends
    # system notifications to
    # Gnome [libnotify](http://developer.gnome.org/libnotify):
    #
    # @example Add the `libnotify` gem to your `Gemfile`
    #   group :development
    #     gem 'libnotify'
    #   end
    #
    # @example Add the `:libnotify` notifier to your `Guardfile`
    #   notification :libnotify
    #
    # @example Add the `:libnotify` notifier with configuration options to your `Guardfile`
    #   notification :libnotify, timeout: 5, transient: true, append: false, urgency: :critical
    #
    class Libnotify < Base

      # Default options for the libnotify notifications.
      DEFAULTS = {
        transient: false,
        append:    true,
        timeout:   3
      }

      def self.supported_hosts
        %w[linux freebsd openbsd sunos solaris]
      end

      def self.available?(opts = {})
        super and require_gem_safely(opts)
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [Boolean] transient keep the notifications around after
      #   display
      # @option opts [Boolean] append append onto existing notification
      # @option opts [Number, Boolean] timeout the number of seconds to display
      #   (1.5 (s), 1000 (ms), false)
      #
      def notify(message, opts = {})
        super
        self.class.require_gem_safely

        opts = DEFAULTS.merge(
          summary:   opts.delete(:title),
          icon_path: opts.delete(:image),
          body:      message,
          urgency:   _libnotify_urgency(opts.delete(:type))
        ).merge(opts)

        ::Libnotify.show(opts)
      end

      private

      # Convert Guards notification type to the best matching
      # libnotify urgency.
      #
      # @param [String] type the Guard notification type
      # @return [Symbol] the libnotify urgency
      #
      def _libnotify_urgency(type)
        case type
        when 'failed'
          :normal
        else
          :low
        end
      end

    end

  end
end
