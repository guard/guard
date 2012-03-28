require 'rbconfig'

module Guard
  module Notifier

    # System notifications using the [libnotify](https://github.com/splattael/libnotify) gem.
    #
    # This gem is available for Linux, FreeBSD, OpenBSD and Solaris and sends system notifications to
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
    #   notification :libnotify, :timeout => 5, :transient => true, :append => false, :urgency => :critical
    #
    module Libnotify
      extend self

      # Default options for libnotify gem
      DEFAULTS = {
        :transient => false,
        :append    => true,
        :timeout   => 3
      }

      # Test if the notification library is available.
      #
      # @param [Boolean] silent true if no error messages should be shown
      # @return [Boolean] the availability status
      #
      def available?(silent = false)
        if RbConfig::CONFIG['host_os'] =~ /linux|freebsd|openbsd|sunos|solaris/
          require 'libnotify'

          true

        else
          ::Guard::UI.error 'The :libnotify notifier runs only on Linux, FreeBSD, OpenBSD and Solaris.' unless silent
          false
        end

      rescue LoadError
        ::Guard::UI.error "Please add \"gem 'libnotify'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
        false
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [Boolean] transient keep the notifications around after display
      # @option options [Boolean] append append onto existing notification
      # @option options [Number, Boolean] timeout the number of seconds to display (1.5 (s), 1000 (ms), false)
      #
      def notify(type, title, message, image, options = { })
        require 'libnotify'

        options = DEFAULTS.merge(options).merge({
          :summary   => title,
          :body      => message,
          :icon_path => image
        })
        options[:urgency] ||= libnotify_urgency(type)
        ::Libnotify.show(options)
      end

      private

      # Convert Guards notification type to the best matching
      # libnotify urgency.
      #
      # @param [String] type the Guard notification type
      # @return [Symbol] the libnotify urgency
      #
      def libnotify_urgency(type)
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
