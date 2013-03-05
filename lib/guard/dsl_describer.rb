# encoding: utf-8

module Guard

  # The DslDescriber overrides methods to create an internal structure
  # of the Guardfile that is used in some inspection utility methods
  # like the CLI commands `show` and `list`.
  #
  # @see Guard::Dsl
  # @see Guard::CLI
  #
  class DslDescriber < Dsl

    require 'guard/dsl'
    require 'guard/ui'

    require 'formatador'

    class << self

      # Setups groups and plugins state and evaluates the DSL methods in the `Guardfile`.
      #
      # @option options [Array<Symbol,String>] groups the groups to evaluate
      # @option options [String] guardfile the path to a valid Guardfile
      # @option options [String] guardfile_contents a string representing the content of a valid Guardfile
      # @raise [ArgumentError] when options are not a Hash
      #
      def evaluate_guardfile(options = { })
        ::Guard.options = { :plugin => [], :group => [] }
        ::Guard.setup_groups
        ::Guard.setup_guards

        super options
      end

      # List the Guard plugins that are available for use in your system and marks
      # those that are currently used in your `Guardfile`.
      #
      # @param [Hash] options the Guard options
      #
      def list(options)
        evaluate_guardfile(options)

        rows = ::Guard.guard_gem_names.sort.uniq.inject([]) do |rows, name|
          rows << { :Plugin => name.capitalize, :Guardfile => ::Guard.guards(name) ? '✔' : '✘' }
        end

        Formatador.display_compact_table(rows, [:Plugin, :Guardfile])
      end

      # Shows all Guard plugins and their options that are defined in
      # the `Guardfile`.
      #
      # @param [Hash] options the Guard options
      #
      def show(options)
        evaluate_guardfile(options)

        rows = ::Guard.groups.inject([]) do |rows, group|
          ::Guard.guards({ :group => group.name }).each do |plugin|
            options = plugin.options.inject({}) { |o, (k, v)| o[k.to_s] = v; o }.sort

            if options.empty?
              rows << :split
              rows << { :Group => group.to_s, :Plugin => plugin.to_s, :Option => '', :Value => '' }
            else
              options.each_with_index do |(option, value), index|
                if index == 0
                  rows << :split
                  rows << { :Group => group.to_s, :Plugin => plugin.to_s, :Option => option.to_s, :Value => value.inspect }
                else
                  rows << { :Group => '', :Plugin => '', :Option => option.to_s, :Value => value.inspect }
                end
              end
            end
          end

          rows
        end

        Formatador.display_compact_table(rows.drop(1), [:Group, :Plugin, :Option, :Value])
      end

    end
  end
end
