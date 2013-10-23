require 'yaml'
require 'rbconfig'
require 'pathname'

require 'guard/ui'
require 'guard/notifiers/emacs'
require 'guard/notifiers/file_notifier'
require 'guard/notifiers/gntp'
require 'guard/notifiers/growl_notify'
require 'guard/notifiers/growl'
require 'guard/notifiers/libnotify'
require 'guard/notifiers/notifysend'
require 'guard/notifiers/rb_notifu'
require 'guard/notifiers/terminal_notifier'
require 'guard/notifiers/terminal_title'
require 'guard/notifiers/tmux'

module Guard

  # The notifier handles sending messages to different notifiers. Currently the
  # following
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
  # Please see the documentation of each notifier for more information about
  # the requirements
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
  # Guard can be configured to make use of more than one notifier at once.
  #
  # @see Guard::Dsl
  #
  module Notifier

    extend self

    # List of available notifiers, grouped by functionality
    NOTIFIERS = [
      {
        gntp: GNTP,
        growl: Growl,
        growl_notify: GrowlNotify,
        terminal_notifier: TerminalNotifier,
        libnotify: Libnotify,
        notifysend: NotifySend,
        notifu: Notifu
      },
      { emacs: Emacs },
      { tmux: Tmux },
      { terminal_title: TerminalTitle },
      { file: FileNotifier }
    ]

    def notifiers
      ENV['GUARD_NOTIFIERS'] ? YAML::load(ENV['GUARD_NOTIFIERS']) : []
    end

    def notifiers=(notifiers)
      ENV['GUARD_NOTIFIERS'] = YAML::dump(notifiers)
    end

    # Clear available notifications.
    #
    def clear_notifiers
      ENV['GUARD_NOTIFIERS'] = nil
    end

    # Turn notifications on. If no notifications are defined in the `Guardfile`
    # Guard auto detects the first available library.
    #
    # @param [Hash] options the turn_on options
    # @option options [Boolean] silent disable any logging
    #
    def turn_on(opts = {})
      _auto_detect_notification if notifiers.empty? && (!::Guard.options || ::Guard.options[:notify])

      if notifiers.empty?
        turn_off
      else
        notifiers.each do |notifier|
          notifier_class = _get_notifier_module(notifier[:name])
          ::Guard::UI.info "Guard is using #{ notifier_class.title } to send notifications." unless opts[:silent]

          notifier_class.turn_on if notifier_class.respond_to?(:turn_on)
        end

        ENV['GUARD_NOTIFY'] = 'true'
      end
    end

    # Turn notifications off.
    #
    def turn_off
      notifiers.each do |notifier|
        notifier_class = _get_notifier_module(notifier[:name])

        notifier_class.turn_off if notifier_class.respond_to?(:turn_off)
      end

      ENV['GUARD_NOTIFY'] = 'false'
    end

    # Toggle the system notifications on/off
    #
    def toggle
      if enabled?
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
    # @param [Hash] options the notifier options
    # @option options [String] silent disable any error message
    # @return [Boolean] if the notification could be added
    #
    def add_notifier(name, opts = {})
      return turn_off if name == :off

      notifier_class = _get_notifier_module(name)

      if notifier_class && notifier_class.available?(opts)
        self.notifiers = notifiers << { name: name, options: opts }
        true
      else
        false
      end
    end

    # Show a system notification with all configured notifiers.
    #
    # @param [String] message the message to show
    # @option opts [Symbol, String] image the image symbol or path to an image
    # @option opts [String] title the notification title
    #
    def notify(message, opts = {})
      return unless enabled?

      notifiers.each do |notifier|
        notifier = _get_notifier_module(notifier[:name]).new(notifier[:options])

        begin
          notifier.notify(message, opts.dup)
        rescue Exception => e
          ::Guard::UI.error "Error sending notification with #{ notifier.name }: #{ e.message }"
          ::Guard::UI.debug e.backtrace.join("\n")
        end
      end
    end

    private

    # Get the notifier module for the given name.
    #
    # @param [Symbol] name the notifier name
    # @return [Module] the notifier module
    #
    def _get_notifier_module(name)
      NOTIFIERS.each do |group|
        if notifier = group.find { |n, _| n == name }
          return notifier.last
        end
      end

      nil
    end

    # Auto detect the available notification library. This goes through
    # the list of supported notification gems and picks the first that
    # is available in each notification group.
    #
    def _auto_detect_notification
      self.notifiers = []
      available = nil

      NOTIFIERS.each do |group|
        notifier_added = group.find { |name, klass| add_notifier(name, silent: true) }
        available ||= notifier_added
      end

      ::Guard::UI.info('Guard could not detect any of the supported notification libraries.') unless available
    end
  end

end
