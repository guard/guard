require 'guard/dsl'

module Guard

  # The DslDescriber overrides methods to create an internal structure
  # of the Guardfile that is used in some inspection utility methods
  # like the CLI commands `show` and `list`.
  #
  # @see Guard::DSL
  # @see Guard::CLI
  #
  class DslDescriber < Dsl

    @@guardfile_structure = [ { :guards => [] } ]

    class << self

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
    # @see Guard::Dsl
    #
    def group(name)
      @@guardfile_structure << { :group => name.to_sym, :guards => [] }
      @group = true

      yield if block_given?

      @group = false
    end

    # Declare a guard.
    #
    # @param [String] name the Guard name
    # @param [Hash] options the options accepted by the Guard
    # @yield a block where you can declare several watch patterns and actions
    #
    # @see Guard::Dsl
    #
    def guard(name, options = {})
      node = (@group ? @@guardfile_structure.last : @@guardfile_structure.first)

      node[:guards] << { :name => name, :options => options }
    end

  end
end
