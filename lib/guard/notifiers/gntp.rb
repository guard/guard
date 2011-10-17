require 'rbconfig'

module Guard
  module Notifier

    # System notifications using the [ruby_gntp](https://github.com/snaka/ruby_gntp) gem.
    #
    # This gem is available for OS X, Linux and Windows and sends system notifications to
    # the following system notification frameworks through the
    # [Growl Network Transport Protocol](http://www.growlforwindows.com/gfw/help/gntp.aspx):
    #
    # * [Growl](http://growl.info)
    # * [Growl for Windows](http://www.growlforwindows.com)
    # * [Growl for Linux](http://mattn.github.com/growl-for-linux)
    # * [Snarl](https://sites.google.com/site/snarlapp/)
    #
    # @example Add the `ruby_gntp` gem to your `Gemfile`
    #   group :development
    #     gem 'ruby_gntp'
    #   end
    #
    # @example Add the `:gntp` notifier to your `Guardfile`
    #   notification :gntp
    #
    # @example Add the `:gntp` notifier with configuration options to your `Guardfile`
    #   notification :growl, :sticky => true, :host => '192.168.1.5', :password => 'secret'
    #
    module GNTP
      extend self

      # Default options for the ruby gtnp gem
      DEFAULTS = {
        :sticky   => false,
        :host     => 'localhost',
        :password => '',
        :port     => 23053
      }

      # Test if the notification library is available.
      #
      # @param [Boolean] silent true if not error message should be shown
      # @return [Boolean] the availability status
      #
      def available?(silent = false)
        if RbConfig::CONFIG['host_os'] =~ /darwin|linux|freebsd|openbsd|sunos|solaris|mswin|mingw/
          require 'ruby_gntp'

        else
          ::Guard::UI.error 'The :gntp notifier runs only on Mac OS X, Linux, FreeBSD, OpenBSD, Solaris and Windows.' unless silent
        end

      rescue LoadError
        ::Guard::UI.error "Please add \"gem 'ruby_gntp'\" to your Gemfile and run Guard with \"bundle exec\"." unless silent
      end

      # Show a system notification.
      #
      # @param [String] type the notification type. Either 'success', 'pending', 'failed' or 'notify'
      # @param [String] title the notification title
      # @param [String] message the notification message body
      # @param [String] image the path to the notification image
      # @param [Hash] options additional notification library options
      # @option options [String] host the hostname or IP address to which to send a remote notification
      # @option options [String] password the password used for remote notifications
      # @option options [Integer] port the port to send a remote notification
      # @option options [Boolean] sticky make the notification sticky
      #
      def notify(type, title, message, image, options = { })
        require 'ruby_gntp'

        ::GNTP.notify(DEFAULTS.merge(options).merge({
            :app_name => 'Guard',
            :name     => type,
            :title    => title,
            :text     => message,
            :icon     => image
        }))
      end

    end
  end
end

