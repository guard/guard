# frozen_string_literal: true

require "formatador"

require "guard/ui"
require "guard/notifier"
require "guard/plugin_util"

require "set"
require "ostruct"

module Guard
  # @private
  # The DslDescriber evaluates the Guardfile and creates an internal structure
  # of it that is used in some inspection utility methods like the CLI commands
  # `show` and `list`.
  #
  # @see Guard::Dsl
  # @see Guard::CLI
  #
  class DslDescriber
    def initialize(guardfile_result)
      @guardfile_result = guardfile_result
    end

    # List the Guard plugins that are available for use in your system and marks
    # those that are currently used in your `Guardfile`.
    #
    # @see CLI#list
    #
    def list
      # collect metadata
      data = PluginUtil.plugin_names.sort.each_with_object({}) do |name, hash|
        hash[name.capitalize] = guardfile_result.plugin_names.include?(name.to_sym)
      end

      # presentation
      header = %i(Plugin Guardfile)
      final_rows = []
      data.each do |name, used|
        final_rows << { Plugin: name, Guardfile: used ? "✔" : "✘" }
      end

      # render
      Formatador.display_compact_table(final_rows, header)
    end

    # Shows all Guard plugins and their options that are defined in
    # the `Guardfile`.
    #
    # @see CLI#show
    #
    def show
      objects = []
      empty_plugin = ["", { "" => nil }]

      guardfile_result.groups.each do |group_name, options|
        plugins = guardfile_result.plugins.select { |plugin| plugin.last[:group] == group_name }
        plugins = [empty_plugin] if plugins.empty?
        plugins.each do |plugin|
          plugin_name, options = plugin
          options.delete(:group)
          options = empty_plugin.last if options.empty?

          options.each do |option, value|
            objects << [group_name, plugin_name, option.to_s, value&.inspect]
          end
        end
      end

      # presentation
      rows = []
      prev_group = prev_plugin = prev_option = prev_value = nil
      objects.each do |group, plugin, option, value|
        group_changed = prev_group != group
        plugin_changed = (prev_plugin != plugin || group_changed)

        rows << :split if group_changed || plugin_changed

        rows << {
          Group: group_changed ? group : "",
          Plugin: plugin_changed ? plugin : "",
          Option: option,
          Value: value
        }

        prev_group = group
        prev_plugin = plugin
        prev_option = option
        prev_value = value
      end

      # render
      Formatador.display_compact_table(
        rows.drop(1),
        %i(Group Plugin Option Value)
      )
    end

    # Shows all notifiers and their options that are defined in
    # the `Guardfile`.
    #
    # @see CLI#show
    #
    def notifiers
      supported = Notifier.supported
      Notifier.connect(notify: true, silent: true)
      detected = Notifier.detected
      Notifier.disconnect

      detected_names = detected.map { |item| item[:name] }

      final_rows = supported.each_with_object([]) do |(name, _), rows|
        available = detected_names.include?(name) ? "✔" : "✘"

        notifier = detected.detect { |n| n[:name] == name }
        used = notifier ? "✔" : "✘"

        options = notifier ? notifier[:options] : {}

        if options.empty?
          rows << :split
          _add_row(rows, name, available, used, "", "")
        else
          options.each_with_index do |(option, value), index|
            if index.zero?
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
        %i(Name Available Used Option Value)
      )
    end

    private

    attr_reader :guardfile_result

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
