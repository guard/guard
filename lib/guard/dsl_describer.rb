require 'guard/dsl'

module Guard

  autoload :UI,    'guard/ui'

  # The DslDescriber overrides methods to create an internal structure
  # of the Guardfile that is used in some inspection utility methods
  # like the CLI commands `show` and `list`.
  #
  # @see Guard::Dsl
  # @see Guard::CLI
  #
  class DslDescriber < Dsl

    class << self

      # Evaluate the DSL methods in the `Guardfile`.
      #
      # @option options [Array<Symbol,String>] groups the groups to evaluate
      # @option options [String] guardfile the path to a valid Guardfile
      # @option options [String] guardfile_contents a string representing the content of a valid Guardfile
      # @raise [ArgumentError] when options are not a Hash
      #
      def evaluate_guardfile(options = {})
        @@guardfile_structure = [{ :guards => [] }]
        super options
      end

      # List the Guards that are available for use in your system and marks
      # those that are currently used in your `Guardfile`.
      #
      # @example Guard list output
      #
      #   Available guards:
      #     bundler *
      #     livereload
      #     ronn
      #     rspec *
      #     spork
      #
      #   See also https://github.com/guard/guard/wiki/List-of-available-Guards
      #   * denotes ones already in your Guardfile
      #
      # @param [Hash] options the Guard options
      #
      def list(options)
        evaluate_guardfile(options)

        installed = guardfile_structure.inject([]) do |installed, group|
          group[:guards].each { |guard| installed << guard[:name] } if group[:guards]
          installed
        end

        UI.info 'Available guards:'

        ::Guard.guard_gem_names.sort.uniq.each do |name|
          UI.info "   #{ name }#{ installed.include?(name) ? '*' : '' }"
        end

        UI.info ''
        UI.info 'See also https://github.com/guard/guard/wiki/List-of-available-Guards'
        UI.info '* denotes ones already in your Guardfile'
      end

      # Shows all Guards and their options that are defined in
      # the `Guardfile`.
      #
      # @example guard show output
      #
      #   (global):
      #     bundler
      #     coffeescript: input => "app/assets/javascripts", noop => true
      #     jasmine
      #     rspec: cli => "--fail-fast --format Fuubar
      #
      # @param [Hash] options the Guard options
      #
      def show(options)
        evaluate_guardfile(options)

        guardfile_structure.each do |group|
          unless group[:guards].empty?
            if group[:group]
              UI.info "Group #{ group[:group] }:"
            else
              UI.info '(global):'
            end

            group[:guards].each do |guard|
              line = "  #{ guard[:name] }"

              unless guard[:options].empty?
                line += ": #{ guard[:options].sort.collect { |k, v| "#{ k } => #{ v.inspect }" }.join(', ') }"
              end

              UI.info line
            end
          end
        end

        UI.info ''
      end

      private

      # Get the Guardfile structure.
      #
      # @return [Array<Hash>] the structure
      #
      def guardfile_structure
        @@guardfile_structure
      end

    end

    private

    # Declares a group of guards.
    #
    # @param [String] name the group's name called from the CLI
    # @yield a block where you can declare several guards
    #
    # @see Guard::Dsl#group
    #
    def group(name)
      @@guardfile_structure << { :group => name.to_sym, :guards => [] }
      @group = true

      yield if block_given?

      @group = false
    end

    # Declares a Guard.
    #
    # @param [String] name the Guard name
    # @param [Hash] options the options accepted by the Guard
    # @yield a block where you can declare several watch patterns and actions
    #
    # @see Guard::Dsl#guard
    #
    def guard(name, options = { })
      node = (@group ? @@guardfile_structure.last : @@guardfile_structure.first)

      node[:guards] << { :name => name, :options => options }
    end

  end
end
