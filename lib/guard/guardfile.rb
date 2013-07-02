require 'guard/guardfile/evaluator'
require 'guard/guardfile/generator'
require 'guard/ui'

module Guard

  # @deprecated Use instance methods of {Guardfile::Evaluator} and
  #  {Guardfile::Generator} instead.
  #
  # @see Guardfile::Evaluator
  # @see Guardfile::Generator
  #
  module Guardfile

    # @deprecated Use {Guardfile::Generator#create_guardfile} instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
    #
    def self.create_guardfile(options = {})
      ::Guard::UI.deprecation(::Guard::Deprecator::CREATE_GUARDFILE_DEPRECATION)
      Generator.new(options).create_guardfile
    end

    # @deprecated Use {Guardfile::Generator#initialize_template} instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
    #
    def self.initialize_template(plugin_name)
      ::Guard::UI.deprecation(::Guard::Deprecator::INITIALIZE_TEMPLATE_DEPRECATION)
      Generator.new.initialize_template(plugin_name)
    end

    # @deprecated Use {Guardfile::Generator#initialize_all_templates} instead.
    #
    # @see https://github.com/guard/guard/wiki/Upgrading-to-Guard-2.0 How to upgrade for Guard 2.0
    #
    def self.initialize_all_templates
      ::Guard::UI.deprecation(::Guard::Deprecator::INITIALIZE_ALL_TEMPLATES_DEPRECATION)
      Generator.new.initialize_all_templates
    end

  end

end
