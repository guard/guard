module Guard
  class Interactor

    ALL = Pry::CommandSet.new do
      create_command 'all' do

        group 'Guard'
        description 'Run all plugins.'

        banner <<-BANNER
          Usage: all <scope>

          Run the Guard plugin `run_all` action.

          You may want to specify an optional scope to the action,
          either the name of a Guard plugin or a plugin group.
        BANNER

        def process(*entries)
          scopes, rest = ::Guard::Interactor.convert_scope(entries)

          if rest.empty?
            ::Guard.run_all scopes
          else
            output.puts "Unkown scope #{ rest.join(', ') }"
          end
        end
      end
    end

  end
end

Pry.commands.import ::Guard::Interactor::ALL
