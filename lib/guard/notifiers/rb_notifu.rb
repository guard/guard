require 'guard/notifiers/base'

module Guard
  module Notifier

    # System notifications using the
    # [rb-notifu](https://github.com/stereobooster/rb-notifu) gem.
    #
    # This gem is available for Windows and sends system notifications to
    # [Notifu](http://www.paralint.com/projects/notifu/index.html):
    #
    # @example Add the `rb-notifu` gem to your `Gemfile`
    #   group :development
    #     gem 'rb-notifu'
    #   end
    #
    # @example Add the `:notifu` notifier to your `Guardfile`
    #   notification :notifu
    #
    # @example Add the `:notifu` notifier with configuration options to your `Guardfile`
    #   notification :notifu, time: 5, nosound: true, xp: true
    #
    class Notifu < Base

      # Default options for the rb-notifu notifications.
      DEFAULTS = {
        time:    3,
        icon:    false,
        baloon:  false,
        nosound: false,
        noquiet: false,
        xp:      false
      }

      def self.supported_hosts
        %w[mswin mingw]
      end

      def self.gem_name
        'rb-notifu'
      end

      def self.available?(opts = {})
        super
        require_gem_safely(opts)
      end

      # Shows a system notification.
      #
      # @param [String] message the notification message body
      # @param [Hash] opts additional notification library options
      # @option opts [String] type the notification type. Either 'success',
      #   'pending', 'failed' or 'notify'
      # @option opts [String] title the notification title
      # @option opts [String] image the path to the notification image
      # @option opts [Number] time the number of seconds to display (0 for
      #   infinit)
      # @option opts [Boolean] icon specify an icon to use ("parent" uses the
      #   icon of the parent process)
      # @option opts [Boolean] baloon enable ballon tips in the registry (for
      #   this user only)
      # @option opts [Boolean] nosound do not play a sound when the tooltip is
      #   displayed
      # @option opts [Boolean] noquiet show the tooltip even if the user is in
      #   the quiet period that follows his very first login (Windows 7 and up)
      # @option opts [Boolean] xp use IUserNotification interface event when
      #   IUserNotification2 is available
      #
      def notify(message, opts = {})
        self.class.require_gem_safely
        normalize_standard_options!(opts)

        opts = DEFAULTS.merge(
          type:    _notifu_type(opts.delete(:type)),
          message: message
        ).merge(opts)

        # The empty block is needed until https://github.com/stereobooster/rb-notifu/pull/1 is merged
        ::Notifu.show(opts) {}
      end

      private

      # Converts Guards notification type to the best matching
      # Notifu type.
      #
      # @param [String] type the Guard notification type
      # @return [Symbol] the Notify notification type
      #
      def _notifu_type(type)
        case type.to_sym
        when :failed
          :error
        when :pending
          :warn
        else
          :info
        end
      end

    end
  end
end
