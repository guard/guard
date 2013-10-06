# encoding: utf-8
require 'formatador'

require 'guard/guardfile/evaluator'
require 'guard/ui'

module Guard

  # The DslDescriber evaluates the Guardfile and creates an internal structure
  # of it that is used in some inspection utility methods like the CLI commands
  # `show` and `list`.
  #
  # @see Guard::Dsl
  # @see Guard::CLI
  #
  class DslDescriber

    attr_reader :options

    # Initializes a new DslDescriber object.
    #
    # @option options [String] guardfile the path to a valid Guardfile
    # @option options [String] guardfile_contents a string representing the content of a valid Guardfile
    #
    # @see Guard::Guardfile::Evaluator#initialize
    #
    def initialize(options = {})
      @options = options
      ::Guard.reset_groups
      ::Guard.reset_plugins
    end

    # List the Guard plugins that are available for use in your system and marks
    # those that are currently used in your `Guardfile`.
    #
    # @see CLI#list
    #
    def list
      _evaluate_guardfile

      rows = ::Guard::PluginUtil.plugin_names.sort.uniq.inject([]) do |rows, name|
        rows << { Plugin: name.capitalize, Guardfile: ::Guard.plugins(name) ? '✔' : '✘' }
      end

      Formatador.display_compact_table(rows, [:Plugin, :Guardfile])
    end

    # Shows all Guard plugins and their options that are defined in
    # the `Guardfile`.
    #
    # @see CLI#show
    #
    def show
      _evaluate_guardfile

      rows = ::Guard.groups.inject([]) do |rows, group|
        Array(::Guard.plugins(group: group.name)).each do |plugin|
          options = plugin.options.inject({}) { |o, (k, v)| o[k.to_s] = v; o }.sort

          if options.empty?
            rows << :split
            rows << { Group: group.title, Plugin: plugin.title, Option: '', Value: '' }
          else
            options.each_with_index do |(option, value), index|
              if index == 0
                rows << :split
                rows << { Group: group.title, Plugin: plugin.title, Option: option.to_s, Value: value.inspect }
              else
                rows << { Group: '', Plugin: '', Option: option.to_s, Value: value.inspect }
              end
            end
          end
        end

        rows
      end

      Formatador.display_compact_table(rows.drop(1), [:Group, :Plugin, :Option, :Value])
    end

    # Shows all notifiers and their options that are defined in
    # the `Guardfile`.
    #
    # @see CLI#show
    #
    def notifiers
      _evaluate_guardfile

      rows = ::Guard::Notifier::NOTIFIERS.inject(:merge).inject([]) do |rows, definition|
        name      = definition[0]
        clazz     = definition[1]
        available = clazz.available?(silent: true) ? '✔' : '✘'
        notifier  = ::Guard::Notifier.notifiers.find { |n| n[:name] == name }
        used      = notifier ? '✔' : '✘'
        options   = notifier ? notifier[:options] : {}
        defaults  = clazz.const_defined?(:DEFAULTS) ? clazz.const_get(:DEFAULTS) : {}
        options   = defaults.merge(options)
        options.delete(:silent)

        if options.empty?
          rows << :split
          rows << { Name: name, Available: available, Used: used, Option: '', Value: '' }
        else
          options.each_with_index do |(option, value), index|
            if index == 0
              rows << :split
              rows << { Name: name, Available: available, Used: used, Option: option.to_s, Value: value.inspect }
            else
              rows << { Name: '', Available: '', Used: '', Option: option.to_s, Value: value.inspect }
            end
          end
        end

        rows
      end

      Formatador.display_compact_table(rows.drop(1), [:Name, :Available, :Used, :Option, :Value])
    end

    private

    # Evaluates the `Guardfile` by delegating to
    #   {Guard::Guardfile::Evaluator#evaluate_guardfile}.
    #
    def _evaluate_guardfile
      ::Guard::Guardfile::Evaluator.new(options).evaluate_guardfile
    end

  end
end
