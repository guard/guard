require 'guard/notifiers/base'

module Guard
  module Notifier

    # System notifications using the
    # [ruby_gntp](https://github.com/snaka/ruby_gntp) gem.
    #
    # This gem is available for OS X, Linux and Windows and sends system
    # notifications to the following system notification frameworks through the
    # [Growl Network Transport Protocol](http://www.growlforwindows.com/gfw/help/gntp.aspx):
    #
    # * [Growl](http://growl.info)
    # * [Growl for Windows](http://www.growlforwindows.com)
    # * [Growl for Linux](http://mattn.github.com/growl-for-linux)
    # * [Snarl](https://sites.google.com/site/snarlapp)
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
    #   notification :gntp, sticky: true, host: '192.168.1.5', password: 'secret'
    #
    class GNTP < Base

      # Default options for the ruby gtnp notifications.
      DEFAULTS = {
        sticky: false
      }

      # Default options for the ruby gtnp client.
      CLIENT_DEFAULTS = {
        host:     '127.0.0.1',
        password: '',
        port:     23053
      }

      def self.supported_hosts
        %w[darwin linux freebsd openbsd sunos solaris mswin mingw cygwin]
      end

      def self.gem_name
        'ruby_gntp'
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
      # @option opts [String] host the hostname or IP address to which to send
      #   a remote notification
      # @option opts [String] password the password used for remote
      #   notifications
      # @option opts [Integer] port the port to send a remote notification
      # @option opts [Boolean] sticky make the notification sticky
      #
      def notify(message, opts = {})
        super
        self.class.require_gem_safely

        opts = DEFAULTS.merge(
          name: opts.delete(:type).to_s,
          text: message,
          icon: opts.delete(:image)
        ).merge(opts)

        _client(opts).notify(opts)
      end

      private

      def _register!(gntp_client)
        gntp_client.register(
          app_icon: images_path.join('guard.png').to_s,
          notifications: [
            { name: 'notify', enabled: true },
            { name: 'failed', enabled: true },
            { name: 'pending', enabled: true },
            { name: 'success', enabled: true }
          ]
        )
      end

      def _client(opts = {})
        @_client ||= begin
          gntp = ::GNTP.new('Guard',
                            opts.delete(:host) { CLIENT_DEFAULTS[:host] },
                            opts.delete(:password) { CLIENT_DEFAULTS[:password] },
                            opts.delete(:port) { CLIENT_DEFAULTS[:port] })
          _register!(gntp)
          gntp
        end
      end

    end

  end
end
