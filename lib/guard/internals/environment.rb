module Guard
  # @private api
  module Internals
    class Environment
      class Error < ArgumentError
      end

      class MethodError < Error
        def initialize(meth)
          @meth = meth
        end
      end

      class NoMethodError < MethodError
        def message
          format("No such method %s", @meth.inspect)
        end
      end

      class AlreadyExistsError < MethodError
        def message
          format("Method %s already exists", @meth.inspect)
        end
      end

      class Loader
        def initialize(meth)
          @bool = meth.to_s.end_with?("?")
        end

        def load(raw_value, &callback)
          return callback.call(raw_value) if callback
          @bool ? _to_bool(raw_value) : raw_value
        end

        private

        def _to_bool(raw_value)
          case raw_value
          when nil
            nil
          when ""
            fail ArgumentError, "Can't convert empty string into Bool"
          when "0", "false"
            false
          else
            true
          end
        end
      end

      class Dumper
        def initialize
        end

        def dump(raw_value, &callback)
          return callback.call(raw_value) if callback
          raw_value.nil? ? nil : raw_value.to_s
        end
      end

      def initialize(namespace)
        @namespace = namespace
        @methods = {}
      end

      def create_method(meth, &block)
        fail AlreadyExistsError, meth if @methods.key?(meth)
        @methods[meth] = block
      end

      # TODO: add respond_to support

      def method_missing(*args)
        meth, raw_value = *args
        fail NoMethodError, meth unless @methods.key?(meth)

        callback = @methods[meth]
        env_name = format("%s_%s", @namespace, _sanitize(meth))

        if args.size == 2
          ENV[env_name] = Dumper.new.dump(raw_value, &callback)
        else
          Loader.new(meth).load(ENV[env_name], &callback)
        end
      end

      private

      def _sanitize(meth)
        meth[/^([^=?]*)[=?]?$/, 1].upcase
      end
    end
  end
end
