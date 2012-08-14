require 'rbconfig'
require 'guard/ui'

module Guard
  module Notifier

    # System notifications using the [rb-notifu](https://github.com/stereobooster/rb-notifu) gem.
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
    #   notification :notifu, :time => 5, :nosound => true, :xp => true
    #
    module Notifu
      extend self

      # Default options for rb-notifu gem
      DEFAULTS = {
        :time    => 3,
        :icon    => false,
        :baloon  => false,
        :nosound => false,
        :noquiet => false,
        :xp      => false
      }

      # Test if the notification library is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @return [Boolean] the availability status
      #
      def available?(silent = false)
        if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/
          require 'rb-notifu'

          true

        else
          ::Guard::UI.error 'The :notifu notifier runs only on Windows.' unless silent
          false
        end

      rescue LoadError
        ::Guard::UI.error "Please add \"gem 'rb-notifu'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
        false
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [Number] time the number of seconds to display (0 for infinit)
      # @option options [Boolean] icon specify an icon to use ("parent" uses the icon of the parent process)
      # @option options [Boolean] baloon enable ballon tips in the registry (for this user only)
      # @option options [Boolean] nosound do not play a sound when the tooltip is displayed
      # @option options [Boolean] noquiet show the tooltip even if the user is in the quiet period that follows his very first login (Windows 7 and up)
      # @option options [Boolean] xp use IUserNotification interface event when IUserNotification2 is available
      #
      def notify(type, title, message, image, options = { })
        require 'rb-notifu'

        ::Notifu.show(DEFAULTS.merge(options).merge({
          :type    => notifu_type(type),
          :title   => title,
          :message => message
        }))
      end

      private

      # Convert Guards notification type to the best matching
      # Notifu type.
      #
      # @param [String] type the Guard notification type
      # @return [Symbol] the Notify notification type
      #
      def notifu_type(type)
        case type
        when 'failed'
          :error
        when 'pending'
          :warn
        else
          :info
        end
      end

    end
  end
end
