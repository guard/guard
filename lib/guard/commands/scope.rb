module Guard
  class Interactor

    SCOPE = Pry::CommandSet.new do
      create_command 'scope' do

        group 'Guard'
        description 'Scope Guard actions to groups and plugins.'

        banner <<-BANNER
          Usage: scope <scope>

          Set the global Guard scope.
        BANNER

        def process(*entries)
          scope, rest = ::Guard::Interactor.convert_scope(entries)

          if rest.length == 0
            ::Guard.scope =  scope
          else
            output.puts "Unkown scope #{ rest.join(', ') }"
          end
        end

      end
    end

  end
end

Pry.commands.import ::Guard::Interactor::SCOPE
