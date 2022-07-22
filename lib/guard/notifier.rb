# frozen_string_literal: true

require "notiffany/notifier"
require "guard/ui"

module Guard
  module Notifier
    # @private
    def self.connect(options = {})
      @notifier ||= nil
      fail "Already connected!" if @notifier

      begin
        opts = options.merge(namespace: "guard", logger: UI)
        @notifier = Notiffany.connect(opts)
      rescue Notiffany::Notifier::Detected::UnknownNotifier => e
        UI.error "Failed to setup notification: #{e.message}"
        fail
      end
    end

    # @private
    def self.disconnect
      @notifier&.disconnect
      @notifier = nil
    end

    # Shows a notification.
    #
    # @param [String] message the message to show in the notification
    # @param [Hash] options the Notiffany #notify options
    #
    def self.notify(message, options = {})
      connect(notify: true) unless @notifier

      @notifier.notify(message, options)
    rescue RuntimeError => e
      UI.error "Notification failed for #{@notifier.class.name}: #{e.message}"
      UI.debug e.backtrace.join("\n")
    end

    def self.turn_on
      @notifier.turn_on
    end

    # @private
    def self.toggle
      unless @notifier.enabled?
        UI.error NOTIFICATIONS_DISABLED
        return
      end

      if @notifier.active?
        UI.info "Turn off notifications"
        @notifier.turn_off
        return
      end

      @notifier.turn_on
    end

    # @private
    # Used by Guard::DslDescriber
    def self.supported
      Notiffany::Notifier::SUPPORTED.inject(:merge)
    end

    # @private
    # Used by Guard::DslDescriber
    def self.detected
      @notifier.available.map do |mod|
        { name: mod.name.to_sym, options: mod.options }
      end
    end
  end
end
