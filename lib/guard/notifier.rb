require 'rbconfig'
require 'pathname'
require 'guard/ui'

module Guard

  # The notifier class handles cross-platform system notifications that supports:
  #
  # - Growl on Mac OS X
  # - Libnotify on Linux
  # - Notifu on Windows
  #
  module Notifier

    # Application name as shown in the specific notification settings
    APPLICATION_NAME = "Guard"

    class << self

      attr_accessor :growl_library, :gntp

      # Turn notifications off.
      #
      def turn_off
        ENV["GUARD_NOTIFY"] = 'false'
      end

      # Turn notifications on. This tries to load the platform
      # specific notification library.
      #
      # @return [Boolean] whether the notification could be enabled.
      #
      def turn_on
        ENV["GUARD_NOTIFY"] = 'true'
        case RbConfig::CONFIG['target_os']
        when /darwin/i
          require_growl
        when /linux/i
          require_libnotify
        when /mswin|mingw/i
          require_rbnotifu
        end
      end

      # Show a message with the system notification.
      #
      # @see .image_path
      #
      # @param [String] the message to show
      # @option options [Symbol, String] image the image symbol or path to an image
      # @option options [String] title the notification title
      #
      def notify(message, options = { })
        if enabled?
          image = options.delete(:image) || :success
          title = options.delete(:title) || "Guard"

          case RbConfig::CONFIG['target_os']
          when /darwin/i
            notify_mac(title, message, image, options)
          when /linux/i
            notify_linux(title, message, image, options)
          when /mswin|mingw/i
            notify_windows(title, message, image, options)
          end
        end
      end

      # Test if the notifications are enabled and available.
      #
      # @return [Boolean] whether the notifications are available
      #
      def enabled?
        ENV["GUARD_NOTIFY"] == 'true'
      end

      private

      # Send a message to Growl either with the `growl` gem or the `growl_notify` gem.
      #
      # @param [String] title the notification title
      # @param [String] message the message to show
      # @param [Symbol, String] the image to user
      # @param [Hash] options the growl options
      #
      def notify_mac(title, message, image, options = { })
        require_growl # need for guard-rspec formatter that is called out of guard scope

        notification = { :title => title, :icon => image_path(image) }.merge(options)

        case self.growl_library
        when :growl_notify
          notification.delete(:name)

          GrowlNotify.send_notification({
              :description      => message,
              :application_name => APPLICATION_NAME
          }.merge(notification))

        when :ruby_gntp
          icon = "file://#{ notification.delete(:icon) }"

          self.gntp.notify({
              :name  => [:pending, :success, :failed].include?(image) ? image.to_s : 'notify',
              :text  => message,
              :icon => icon
          }.merge(notification))

        when :growl
          Growl.notify(message, {
              :name => APPLICATION_NAME
          }.merge(notification))
        end
      end

      # Send a message to libnotify.
      #
      # @param [String] title the notification title
      # @param [String] message the message to show
      # @param [Symbol, String] the image to user
      # @param [Hash] options the libnotify options
      #
      def notify_linux(title, message, image, options = { })
        require_libnotify # need for guard-rspec formatter that is called out of guard scope

        notification = { :body => message, :summary => title, :icon_path => image_path(image), :transient => true }
        Libnotify.show notification.merge(options)
      end

      # Send a message to notifu.
      #
      # @param [String] title the notification title
      # @param [String] message the message to show
      # @param [Symbol, String] the image to user
      # @param [Hash] options the notifu options
      #
      def notify_windows(title, message, image, options = { })
        require_rbnotifu # need for guard-rspec formatter that is called out of guard scope

        notification = { :message => message, :title => title, :type => image_level(image), :time => 3 }
        Notifu.show notification.merge(options)
      end

      # Get the image path for an image symbol.
      #
      # Known symbols are:
      #
      # - failed
      # - pending
      # - success
      #
      # @param [Symbol] image the image name
      # @return [String] the image path
      #
      def image_path(image)
        images_path = Pathname.new(File.dirname(__FILE__)).join('../../images')
        case image
        when :failed
          images_path.join("failed.png").to_s
        when :pending
          images_path.join("pending.png").to_s
        when :success
          images_path.join("success.png").to_s
        else
          # path given
          image
        end
      end

      # The notification level type for the given image.
      #
      # @param [Symbol] image the image
      # @return [Symbol] the level
      #
      def image_level(image)
        case image
        when :failed
          :error
        when :pending
          :warn
        when :success
          :info
        else
          :info
        end
      end

      # Try to safely load growl and turns notifications off on load failure.
      # The Guard notifier knows three different library to handle sending
      # Growl messages and tries to loading them in the given order:
      #
      # - [Growl Notify](https://github.com/scottdavis/growl_notify)
      # - [Ruby GNTP](https://github.com/snaka/ruby_gntp)
      # - [Growl](https://github.com/visionmedia/growl)
      #
      # On successful loading of any of the libraries, the active library name is
      # accessible through `.growl_library`.
      #
      def require_growl
        self.growl_library = try_growl_notify || try_ruby_gntp || try_growl

        unless self.growl_library
          turn_off
          UI.info "Please install growl_notify or growl gem for Mac OS X notification support and add it to your Gemfile"
        end
      end

      # Try to load the `growl_notify` gem.
      #
      # @return [Symbol, nil] A symbol with the name of the loaded library
      #
      def try_growl_notify
        require 'growl_notify'

        begin
          if GrowlNotify.application_name != APPLICATION_NAME
            GrowlNotify.config do |c|
              c.notifications    = c.default_notifications = [APPLICATION_NAME]
              c.application_name = c.notifications.first
            end
          end

        rescue ::GrowlNotify::GrowlNotFound
          turn_off
          UI.info "Please install Growl from http://growl.info"
        end

        :growl_notify

      rescue LoadError
      end

      # Try to load the `ruby_gntp` gem and register the available
      # notification channels.
      #
      # @return [Symbol, nil] A symbol with the name of the loaded library
      #
      def try_ruby_gntp
        require 'ruby_gntp'

        self.gntp = GNTP.new(APPLICATION_NAME)
        self.gntp.register(:notifications => [
            { :name => 'notify', :enabled => true },
            { :name => 'failed', :enabled => true },
            { :name => 'pending', :enabled => true },
            { :name => 'success', :enabled => true }
        ])

        :ruby_gntp

      rescue LoadError
      end

      # Try to load the `growl_notify` gem.
      #
      # @return [Symbol, nil] A symbol with the name of the loaded library
      #
      def try_growl
        require 'growl'

        :growl

      rescue LoadError
      end

      # Try to safely load libnotify and turns notifications
      # off on load failure.
      #
      def require_libnotify
        require 'libnotify'

      rescue LoadError
        turn_off
        UI.info "Please install libnotify gem for Linux notification support and add it to your Gemfile"
      end

      # Try to safely load rb-notifu and turns notifications
      # off on load failure.
      #
      def require_rbnotifu
        require 'rb-notifu'

      rescue LoadError
        turn_off
        UI.info "Please install rb-notifu gem for Windows notification support and add it to your Gemfile"
      end

    end
  end
end
