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

    # Turn notifications off.
    #
    def self.turn_off
      ENV["GUARD_NOTIFY"] = 'false'
    end

    # Turn notifications on. This tries to load the platform
    # specific notification library.
    #
    # @return [Boolean] whether the notification could be enabled.
    #
    def self.turn_on
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
    def self.notify(message, options = {})
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
    def self.enabled?
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
    def self.notify_mac(title, message, image, options = {})
      require_growl # need for guard-rspec formatter that is called out of guard scope

      default_options = { :title => title, :icon => image_path(image), :name => APPLICATION_NAME }
      default_options.merge!(options)

      if defined?(GrowlNotify)
        default_options[:description] = message
        default_options[:application_name] = APPLICATION_NAME
        default_options.delete(:name)

        GrowlNotify.send_notification(default_options) if enabled?
      else
        Growl.notify message, default_options.merge(options) if enabled?
      end
    end

    # Send a message to libnotify.
    #
    # @param [String] title the notification title
    # @param [String] message the message to show
    # @param [Symbol, String] the image to user
    # @param [Hash] options the libnotify options
    #
    def self.notify_linux(title, message, image, options = {})
      require_libnotify # need for guard-rspec formatter that is called out of guard scope
      default_options = { :body => message, :summary => title, :icon_path => image_path(image), :transient => true }
      Libnotify.show default_options.merge(options) if enabled?
    end

    # Send a message to notifu.
    #
    # @param [String] title the notification title
    # @param [String] message the message to show
    # @param [Symbol, String] the image to user
    # @param [Hash] options the notifu options
    #
    def self.notify_windows(title, message, image, options = {})
      require_rbnotifu # need for guard-rspec formatter that is called out of guard scope
      default_options = { :message => message, :title => title, :type => image_level(image), :time => 3 }
      Notifu.show default_options.merge(options) if enabled?
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
    def self.image_path(image)
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
    def self.image_level(image)
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

    # Try to safely load growl and turns notifications
    # off on load failure.
    #
    def self.require_growl
      begin
        require 'growl_notify'

        if GrowlNotify.application_name != APPLICATION_NAME
          GrowlNotify.config do |c|
            c.notifications = c.default_notifications = [ APPLICATION_NAME ]
            c.application_name = c.notifications.first
          end
        end
      rescue LoadError
        require 'growl'
      rescue ::GrowlNotify::GrowlNotFound
        turn_off
        UI.info "Please install Growl from http://growl.info"
      end
    rescue LoadError
      turn_off
      UI.info "Please install growl_notify or growl gem for Mac OS X notification support and add it to your Gemfile"
    end

    # Try to safely load libnotify and turns notifications
    # off on load failure.
    #
    def self.require_libnotify
      require 'libnotify'
    rescue LoadError
      turn_off
      UI.info "Please install libnotify gem for Linux notification support and add it to your Gemfile"
    end

    # Try to safely load rb-notifu and turns notifications
    # off on load failure.
    #
    def self.require_rbnotifu
      require 'rb-notifu'
    rescue LoadError
      turn_off
      UI.info "Please install rb-notifu gem for Windows notification support and add it to your Gemfile"
    end

  end
end
