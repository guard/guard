require "yaml"
require "rbconfig"
require "pathname"

require_relative "internals/environment"
require_relative "notifier/detected"

require_relative "ui"

module Guard
  # The notifier handles sending messages to different notifiers. Currently the
  # following libraries are supported:
  #
  # * Ruby GNTP
  # * Growl
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
  # `gntp` notifier is able to register these types
  # at Growl and allows customization of each notification type.
  #
  # Guard can be configured to make use of more than one notifier at once.
  #
  # @see Guard::Dsl
  #
  # TODO: rename to plural
  module Notifier
    extend self

    NOTIFICATIONS_DISABLED = "Notifications disabled by GUARD_NOTIFY" +
      " environment variable"

    USING_NOTIFIER = "Guard is using %s to send notifications."

    ONLY_NOTIFY = "Only notify() is available from a child process"

    DEPRECTED_IMPLICIT_CONNECT = "Calling Guard::Notifier.notify()" +
      " without a prior Notifier.connect() is deprecated"

    # List of available notifiers, grouped by functionality
    SUPPORTED = [
      {
        gntp: GNTP,
        growl: Growl,
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

    class NotServer < RuntimeError
    end

    def connect(options = {})
      @detected = Detected.new(SUPPORTED)
      return if _client?

      _env.notify_pid = $$

      fail "Already connected" if active?

      return unless enabled? && options[:notify]

      @detected.detect

      turn_on
    rescue Detected::NoneAvailableError => e
      ::Guard::UI.info e.to_s
    end

    def disconnect
      if _client?
        @detected = nil
        return
      end

      turn_off if active?
      @detected.reset unless @detected.nil?
      _env.notify_pid = nil
      @detected = nil
    end

    # Turn notifications on.
    #
    # @param [Hash] options the turn_on options
    # @option options [Boolean] silent disable any logging
    #
    def turn_on(options = {})
      _check_server!
      return unless enabled?

      fail "Already active!" if active?

      silent = options[:silent]

      @detected.available.each do |klass, _|
        ::Guard::UI.info(format(USING_NOTIFIER, klass.title)) unless silent
        klass.turn_on if klass.respond_to?(:turn_on)
      end

      _env.notify_active = true
    end

    # Turn notifications off.
    def turn_off
      _check_server!

      fail "Not active!" unless active?

      @detected.available.each do |klass, _|
        klass.turn_off if klass.respond_to?(:turn_off)
      end

      _env.notify_active = false
    end

    # Toggle the system notifications on/off
    def toggle
      unless enabled?
        ::Guard::UI.error NOTIFICATIONS_DISABLED
        return
      end

      if active?
        ::Guard::UI.info "Turn off notifications"
        turn_off
        return
      end

      turn_on
    end

    # Test if the notifications can be enabled based on ENV['GUARD_NOTIFY']
    def enabled?
      _env.notify?
    end

    # Test if notifiers are currently turned on
    def active?
      _env.notify_active?
    end

    # Add a notification library to be used.
    #
    # @param [Symbol] name the name of the notifier to use
    # @param [Hash] options the notifier options
    # @option options [String] silent disable any error message
    # @return [Boolean] if the notification could be added
    #
    def add(name, options = {})
      _check_server!

      return false unless enabled?

      if name == :off && active?
        turn_off
        return false
      end

      # ok to pass new instance when called without connect (e.g. evaluator)
      (@detected || Detected.new(SUPPORTED)).add(name, options)
    end

    # TODO: deprecate/remove
    alias :add_notifier  :add

    # Show a system notification with all configured notifiers.
    #
    # @param [String] message the message to show
    # @option opts [Symbol, String] image the image symbol or path to an image
    # @option opts [String] title the notification title
    #
    def notify(message, message_opts = {})
      if _client?
        # TODO: reenable again?
        # UI.deprecation(DEPRECTED_IMPLICIT_CONNECT)
        return unless enabled?
        connect(notify: true)
      else
        return unless active?
      end

      @detected.available.each do |klass, options|
        _notify(klass, options, message, message_opts)
      end
    end

    # Used by dsl describer
    def notifiers
      @detected.available.map { |mod, opts| { name: mod.name, options: opts } }
    end

    private

    def _env
      (@environment ||= _create_env)
    end

    def _create_env
      Internals::Environment.new("GUARD").tap do |env|
        env.create_method(:notify?) { |data| data != "false" }
        env.create_method(:notify_pid) { |data| data && Integer(data) }
        env.create_method(:notify_pid=)
        env.create_method(:notify_active?)
        env.create_method(:notify_active=)
      end
    end

    def _check_server!
      _client? && fail(NotServer, ONLY_NOTIFY)
    end

    def _client?
      (pid = _env.notify_pid) && (pid != $$)
    end

    def _notify(klass, options, message, message_options)
      notifier = klass.new(options)
      notifier.notify(message, message_options.dup)
    rescue RuntimeError => e
      ::Guard::UI.error "Notification failed for #{notifier.name}: #{e.message}"
      ::Guard::UI.debug e.backtrace.join("\n")
    end
  end
end
