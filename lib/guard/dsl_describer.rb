require 'guard/dsl'

module Guard
  class DslDescriber < Dsl
    @@guardfile_structure = [ { :guards => [] } ]

    class << self
      def guardfile_structure
        @@guardfile_structure
      end
    end

    private
    def group(name, &guard_definition)
      @@guardfile_structure << { :group => name.to_sym, :guards => [] }

      @group = true
      guard_definition.call
      @group = false
    end

    def guard(name, options = {}, &watch_definition)
      node = (@group ? @@guardfile_structure.last : @@guardfile_structure.first)

      node[:guards] << { :name => name, :options => options }
    end
  end
end
