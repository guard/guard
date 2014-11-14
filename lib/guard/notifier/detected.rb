require "guard/internals/environment"

require_relative "../notifiers/emacs"
require_relative "../notifiers/file_notifier"
require_relative "../notifiers/gntp"
require_relative "../notifiers/growl"
require_relative "../notifiers/libnotify"
require_relative "../notifiers/notifysend"
require_relative "../notifiers/rb_notifu"
require_relative "../notifiers/terminal_notifier"
require_relative "../notifiers/terminal_title"
require_relative "../notifiers/tmux"

module Guard
  module Notifier
    # @private api
    class Detected
      NO_SUPPORTED_NOTIFIERS = "Guard could not detect any of the supported" +
        " notification libraries."

      class NoneAvailableError < RuntimeError
      end

      def initialize(supported)
        @supported = supported
        @environment = Internals::Environment.new("GUARD").tap do |env|
          env.create_method(:notifiers=) { |data| YAML::dump(data) }
          env.create_method(:notifiers) { |data| data ? YAML::load(data) : [] }
        end
      end

      def reset
        @environment.notifiers = nil
      end

      def detect
        return unless _data.empty?
        @supported.each do |group|
          group.detect { |name, _| add(name, silent: true) }
        end

        fail NoneAvailableError, NO_SUPPORTED_NOTIFIERS if _data.empty?
      end

      def available
        _data.map { |entry| [_to_module(entry[:name]), entry[:options]] }
      end

      def add(name, opts)
        klass = _to_module(name)
        return false unless klass

        all = @environment.notifiers

        # Silently skip if it's already available, because otherwise
        # we'd have to do :turn_off, then configure, then :turn_on
        names = all.map(&:first).map(&:last)
        unless names.include?(name)
          return false unless klass.available?(opts)
          @environment.notifiers = all << { name: name, options: opts }
          true
        end

        # Just overwrite the options (without turning the notifier off or on),
        # so those options will be passed in next calls to notify()
        all.each { |item| item[:options] = opts if item[:name] == name }
        true
      end

      def _to_module(name)
        @supported.each do |group|
          next unless (notifier = group.detect { |n, _| n == name })
          return notifier.last
        end
        nil
      end

      def _data
        @environment.notifiers || []
      end
    end
  end
end
