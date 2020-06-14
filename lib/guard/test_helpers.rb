# frozen_string_literal: true

require "guard/engine"

module Guard
  # @private
  module TestHelpers
    extend self

    def self.plugin_options
      { engine: Engine.new }
    end

    class Template
      class Session
        class MultipleGuardNotImplemented < RuntimeError
          def message
            "multiple guards not supported!"
          end
        end

        class GlobalWatchesNotImplemented < RuntimeError
          def message
            "global watches not supported!"
          end
        end

        def initialize(path, content)
          @watches = {}
          @current = nil
          instance_eval(content, path, 1)
        end

        def engine
          @engine ||= Guard::Engine.new
        end

        def match(file)
          _watches.map do |expr, block|
            next unless (match = file.match(expr))

            block.nil? ? [file] : block.call([file] + match.captures)
          end.flatten.compact.uniq
        end

        def guard(name, _options = {})
          @current = name
          @watches[@current] = []
          yield
          @current = nil
        end

        def watch(expr, &block)
          @watches[@current] << [expr, block]
        end

        private

        def _watches
          keys = @watches.keys
          fail ArgumentError, "no watches!" if keys.empty?
          fail MultipleGuardNotImplemented if keys.size > 1

          key = keys.first
          fail GlobalWatchesNotImplemented unless key

          @watches[key]
        end
      end

      def initialize(plugin_class)
        name = plugin_class.to_s.sub("Guard::", "").downcase
        path = format("lib/guard/%<plugin_name>s/templates/Guardfile", plugin_name: name)
        content = File.read(path)
        @session = Session.new(path, content)
      end

      def changed(file)
        @session.match(file)
      end
    end
  end
end
