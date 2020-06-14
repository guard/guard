# frozen_string_literal: true

require "guard/options"

module Guard
  module UI
    # @private
    class Config < Guard::Options
      DEFAULTS = {
        only: nil,
        except: nil,

        # nil (will be whatever $stderr is later) or LumberJack device, e.g.
        # $stderr or 'foo.log'
        device: nil,
      }.freeze

      def initialize(options = {})
        opts = Guard::Options.new(options, DEFAULTS)

        super(opts.to_hash)
      end

      def device
        # Use strings to work around Thor's indifferent Hash's bug
        fetch("device") || $stderr
      end

      def only
        fetch("only")
      end

      def except
        fetch("except")
      end

      def [](name)
        name = name.to_s

        return device if name == "device"

        # let Thor's Hash handle anything else
        super(name.to_s)
      end

      def with_progname(name)
        if Guard::UI.logger.respond_to?(:set_progname)
          Guard::UI.logger.set_progname(name) do
            yield if block_given?
          end
        elsif block_given?
          yield
        end
      end
    end
  end
end
