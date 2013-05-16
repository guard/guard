module Guard

  # @deprecated Use instance methods of `Guard::Guardfile::Evaluator` and
  #   `Guard::Guardfile::Generator` instead.
  #
  # @see Guardfile::Evaluator
  # @see Guardfile::Generator
  #
  module Guardfile

    require 'guard/guardfile/evaluator'
    require 'guard/guardfile/generator'
    require 'guard/ui'

    class << self

      # @deprecated Use `Guard::Guardfile::Generator.new(options).create_guardfile` instead.
      #
      # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
      #
      def create_guardfile(options = {})
        ::Guard::UI.deprecation(::Guard::Deprecator::CREATE_GUARDFILE_DEPRECATION)
        Generator.new(options).create_guardfile
      end

      # @deprecated Use `Guard::Guardfile::Generator.new.initialize_template(plugin_name)` instead.
      #
      # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
      #
      def initialize_template(plugin_name)
        ::Guard::UI.deprecation(::Guard::Deprecator::INITIALIZE_TEMPLATE_DEPRECATION)
        Generator.new.initialize_template(plugin_name)
      end

      # @deprecated Use `Guard::Guardfile::Generator.new.initialize_all_templates` instead.
      #
      # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
      #
      def initialize_all_templates
        ::Guard::UI.deprecation(::Guard::Deprecator::INITIALIZE_ALL_TEMPLATES_DEPRECATION)
        Generator.new.initialize_all_templates
      end

    end

  end

end
