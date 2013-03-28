require 'yaml'
require 'rbconfig'
require 'pathname'

module Guard

  # The notifier handles sending messages to different notifiers. Currently the following
  # libraries are supported:
  #
  # * Ruby GNTP
  # * Growl
  # * GrowlNotify
  # * Libnotify
  # * rb-notifu
  # * emacs
  # * Terminal Notifier
  # * Terminal Title
  # * Tmux
  #
  # Please see the documentation of each notifier for more information about the requirements
  # and configuration possibilities.
  #
  # Guard knows four different notification types:
  #
  # * success
  # * pending
  # * failed
  # * notify
  #
  # The notification type selection is based on the image option that is
  # sent to {#notify}. Each image type has its own notification type, and
  # notifications with custom images goes all sent as type `notify`. The
  # `gntp` and `growl_notify` notifiers are able to register these types
  # at Growl and allows customization of each notification type.
  #
  # Guard can be configured to make use of more than one notifier at once, @see Guard::Dsl
  #
  module Notifier

    require 'guard'
    require 'guard/ui'
    require 'guard/notifiers/gntp'
    require 'guard/notifiers/growl'
    require 'guard/notifiers/growl_notify'
    require 'guard/notifiers/libnotify'
    require 'guard/notifiers/notifysend'
    require 'guard/notifiers/rb_notifu'
    require 'guard/notifiers/emacs'
    require 'guard/notifiers/terminal_notifier'
    require 'guard/notifiers/terminal_title'
    require 'guard/notifiers/tmux'
    require 'guard/notifiers/file_notifier'

    extend self

    # List of available notifiers, grouped by functionality. It needs to be a nested hash instead of
    # a simpler Hash, because it maintains its order on Ruby 1.8.7 also.
    NOTIFIERS = [
      [
        [:gntp,              ::Guard::Notifier::GNTP],
        [:growl,             ::Guard::Notifier::Growl],
        [:growl_notify,      ::Guard::Notifier::GrowlNotify],
        [:terminal_notifier, ::Guard::Notifier::TerminalNotifier],
        [:libnotify,         ::Guard::Notifier::Libnotify],
        [:notifysend,        ::Guard::Notifier::NotifySend],
        [:notifu,            ::Guard::Notifier::Notifu]
      ],
      [[:emacs,             ::Guard::Notifier::Emacs]],
      [[:tmux,              ::Guard::Notifier::Tmux]],
      [[:terminal_title,    ::Guard::Notifier::TerminalTitle]],
      [[:file,              ::Guard::Notifier::FileNotifier]]
    ]

    # Get the available notifications.
    #
    # @return [Hash] the notifications
    #
    def notifications
      ENV['GUARD_NOTIFICATIONS'] ? YAML::load(ENV['GUARD_NOTIFICATIONS']) : []
    end

    # Set the available notifications.
    #
    # @param [Array<Hash>] notifications the notifications
    #
    def notifications=(notifications)
      ENV['GUARD_NOTIFICATIONS'] = YAML::dump(notifications)
    end

    # Clear available notifications.
    #
    def clear_notifications
      ENV['GUARD_NOTIFICATIONS'] = nil
    end

    # Turn notifications on. If no notifications are defined
    # in the `Guardfile` Guard auto detects the first available
    # library.
    #
    def turn_on
      auto_detect_notification if notifications.empty? && (!::Guard.options || ::Guard.options[:notify])

      if notifications.empty?
        ENV['GUARD_NOTIFY'] = 'false'
      else
        notifications.each do |notification|
          ::Guard::UI.info "Guard uses #{ get_notifier_module(notification[:name]).to_s.split('::').last } to send notifications."
          notifier = get_notifier_module(notification[:name])
          notifier.turn_on(notification[:options]) if notifier.respond_to?(:turn_on)
        end

        ENV['GUARD_NOTIFY'] = 'true'
      end
    end

    # Turn notifications off.
    #
    def turn_off
      notifications.each do |notification|
        notifier = get_notifier_module(notification[:name])
        notifier.turn_off(notification[:options]) if notifier.respond_to?(:turn_off)
      end

      ENV['GUARD_NOTIFY'] = 'false'
    end

    # Toggle the system notifications on/off
    #
    def toggle
      if ENV['GUARD_NOTIFY'] == 'true'
        ::Guard::UI.info 'Turn off notifications'
        turn_off
      else
        turn_on
      end
    end

    # Test if the notifications are on.
    #
    # @return [Boolean] whether the notifications are on
    #
    def enabled?
      ENV['GUARD_NOTIFY'] == 'true'
    end

    # Add a notification library to be used.
    #
    # @param [Symbol] name the name of the notifier to use
    # @param [Boolean] silent disable any error message
    # @param [Hash] options the notifier options
    # @return [Boolean] if the notification could be added
    #
    def add_notification(name, options = { }, silent = false)
      return turn_off if name == :off

      notifier = get_notifier_module(name)

      if notifier && notifier.available?(silent, options)
        self.notifications = notifications << { :name => name, :options => options }
        true
      else
        false
      end
    end

    # Show a system notification with all configured notifiers.
    #
    # @param [String] message the message to show
    # @option options [Symbol, String] image the image symbol or path to an image
    # @option options [String] title the notification title
    #
    def notify(message, options = { })
      if enabled?
        type  = notification_type(options[:image] || :success)
        image = image_path(options.delete(:image) || :success)
        title = options.delete(:title) || 'Guard'

        notifications.each do |notification|
          begin
            get_notifier_module(notification[:name]).notify(type, title, message, image, options.merge(notification[:options]))
          rescue Exception => e
            ::Guard::UI.error "Error sending notification with #{ notification[:name] }: #{ e.message }"
          end
        end
      end
    end

    private

    # Get the notifier module for the given name.
    #
    # @param [Symbol] name the notifier name
    # @return [Module] the notifier module
    #
    def get_notifier_module(name)
      notifier = NOTIFIERS.flatten(1).detect { |n| n.first == name }
      notifier ? notifier.last : notifier
    end

    # Auto detect the available notification library. This goes through
    # the list of supported notification gems and picks the first that
    # is available in each notification group.
    #
    def auto_detect_notification
      available = nil
      self.notifications = []

      NOTIFIERS.each do |group|
        added = group.map { |n| n.first }.find { |notifier| add_notification(notifier, { }, true) }
        available = available || added
      end

      ::Guard::UI.info('Guard could not detect any of the supported notification libraries.') unless available
    end

    # Get the image path for an image symbol for the following
    # known image types:
    #
    # - failed
    # - pending
    # - success
    #
    # If the image is not a known symbol, it will be returned unmodified.
    #
    # @param [Symbol, String] image the image symbol or path to an image
    # @return [String] the image path
    #
    def image_path(image)
      case image
        when :failed
          images_path.join('failed.png').to_s
        when :pending
          images_path.join('pending.png').to_s
        when :success
          images_path.join('success.png').to_s
        else
          image
      end
    end

    # Paths where all Guard images are located
    #
    # @return [Pathname] the path to the images directory
    #
    def images_path
      @images_path ||= Pathname.new(File.dirname(__FILE__)).join('../../images')
    end

    # Get the notification type depending on the
    # image that has been selected for the notification.
    #
    # @param [Symbol, String] image the image symbol or path to an image
    # @return [String] the notification type
    #
    def notification_type(image)
      case image
        when :failed
          'failed'
        when :pending
          'pending'
        when :success
          'success'
        else
          'notify'
      end
    end
  end

end
