# encoding: utf-8
require "formatador"

require "guard/ui"
require "guard/notifier"

require "set"
require "ostruct"

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
      # collect metadata
      data = PluginUtil.plugin_names.sort.inject({}) do |hash, name|
        hash[name.capitalize] = Guard.state.session.plugins.all(name).any?
        hash
      end

      # presentation
      header = [:Plugin, :Guardfile]
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
      # collect metadata
      groups = Guard.state.session.groups.all

      objects = []

      empty_plugin = OpenStruct.new
      empty_plugin.options = [["", nil]]

      groups.each do |group|
        plugins = Array(Guard.state.session.plugins.all(group: group.name))
        plugins = [empty_plugin] if plugins.empty?
        plugins.each do |plugin|
          options = plugin.options
          options = [["", nil]] if options.empty?
          options.each do |option, raw_value|
            value = raw_value.nil? ? "" : raw_value.inspect
            objects << [group.title, plugin.title, option.to_s, value]
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
