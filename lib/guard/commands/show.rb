require 'guard/dsl_describer'

module Guard
  class Interactor

    SHOW = Pry::CommandSet.new do
      create_command 'show' do

        group 'Guard'
        description 'Show all Guard plugins.'

        banner <<-BANNER
          Usage: show

          Show all defined Guard plugins and their options.
        BANNER

        def process
          ::Guard::DslDescriber.new(::Guard.options).show
        end
      end
    end

  end
end

Pry.commands.import ::Guard::Interactor::SHOW
