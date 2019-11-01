# frozen_string_literal: true

module Guard
  # @deprecated Every method in this module is deprecated
  module Deprecated
    class Options < Hash
      def initialize
        super(to_hash)
      end

      def to_hash
        session = ::Guard.state.session
        {
          clear: session.clearing?,
          debug: session.debug?,
          watchdir: Array(session.watchdirs).map(&:to_s),
          notify: session.notify_options[:notify],
          no_interactions: (session.interactor_name == :sleep)
        }
      end

      extend Forwardable
      delegate %i(to_a keys) => :to_hash
      delegate [:include?] => :keys

      def fetch(key, *args)
        hash = to_hash
        verify_key!(hash, key)
        hash.fetch(key, *args)
      end

      def []=(key, value)
        case key
        when :clear
          ::Guard.state.session.clearing(value)
        else
          msg = "Oops! Guard.option[%s]= is unhandled or unsupported." \
            "Please file an issue if you rely on this option working."
          fail NotImplementedError, format(msg, key)
        end
      end

      private

      def verify_key!(hash, key)
        return if hash.key?(key)

        msg = "Oops! Guard.option[%s] is unhandled or unsupported." \
          "Please file an issue if you rely on this option working."
        fail NotImplementedError, format(msg, key)
      end
    end
  end
end
