# encoding: utf-8
require "formatador"

require "guard/ui"
require "guard/notifier"
require "guard/metadata"

module Guard
  # The DslDescriber evaluates the Guardfile and creates an internal structure
  # of it that is used in some inspection utility methods like the CLI commands
  # `show` and `list`.
  #
  # @see Guard::Dsl
  # @see Guard::CLI
  #
  class DslDescriber
    def initialize(options = nil)
      fail "options passed to DslDescriber are ignored!" unless options.nil?
    end

    # List the Guard plugins that are available for use in your system and marks
    # those that are currently used in your `Guardfile`.
    #
    # @see CLI#list
    #
    def list
      # TODO: use Guard::Metadata
      names = ::Guard::PluginUtil.plugin_names.sort.uniq
      final_rows = names.inject([]) do |rows, name|
        used = ::Guard.plugins(name).any?
        rows << {
          Plugin: name.capitalize,
          Guardfile: used ? "✔" : "✘"
        }
      end

      Formatador.display_compact_table(final_rows, [:Plugin, :Guardfile])
    end

    # Shows all Guard plugins and their options that are defined in
    # the `Guardfile`.
    #
    # @see CLI#show
    #
    def show
      groups = ::Guard.groups

      final_rows = groups.each_with_object([]) do |group, rows|

        plugins = Array(::Guard.plugins(group: group.name))

        plugins.each do |plugin|
          options = plugin.options.inject({}) do |o, (k, v)|
            o.tap { |option| option[k.to_s] = v }
          end.sort

          if options.empty?
            rows << :split
            rows << {
              Group: group.title,
              Plugin: plugin.title,
              Option: "",
              Value: ""
            }
          else
            options.each_with_index do |(option, value), index|
              if index == 0
                rows << :split
                rows << {
                  Group: group.title,
                  Plugin: plugin.title,
                  Option: option.to_s,
                  Value: value.inspect
                }
              else
                rows << {
                  Group: "",
                  Plugin: "",
                  Option: option.to_s,
                  Value: value.inspect
                }
              end
            end
          end
        end

        rows
      end

      Formatador.display_compact_table(
        final_rows.drop(1),
        [:Group, :Plugin, :Option, :Value]
      )
    end

    # Shows all notifiers and their options that are defined in
    # the `Guardfile`.
    #
    # @see CLI#show
    #
    def notifiers
      supported = ::Guard::Notifier::SUPPORTED
      Notifier.connect(notify: false)
      detected = Notifier.notifiers
      Notifier.disconnect

      merged_notifiers = supported.inject(:merge)
      final_rows = merged_notifiers.each_with_object([]) do |definition, rows|

        name      = definition[0]
        clazz     = definition[1]
        available = clazz.available?(silent: true) ? "✔" : "✘"
        notifier  = detected.detect { |n| n[:name] == name }
        used      = notifier ? "✔" : "✘"

        options = _merge_options(clazz, notifier)
        options.delete(:silent)

        if options.empty?
          rows << :split
          _add_row(rows, name, available, used, "", "")
        else
          options.each_with_index do |(option, value), index|
            if index == 0
              rows << :split
              _add_row(rows, name, available, used, option.to_s, value.inspect)
            else
              _add_row(rows, "", "", "", option.to_s, value.inspect)
            end
          end
        end

        rows
      end

      Formatador.display_compact_table(
        final_rows.drop(1),
        [:Name, :Available, :Used, :Option, :Value]
      )
    end

    private

    def _merge_options(klass, notifier)
      notify_options = notifier ? notifier[:options] : {}

      if klass.const_defined?(:DEFAULTS)
        klass.const_get(:DEFAULTS).merge(notify_options)
      else
        notify_options
      end
    end

    def _add_row(rows, name, available, used, option, value)
      rows << {
        Name: name,
        Available: available,
        Used: used,
        Option: option,
        Value: value
      }
    end
  end
end
