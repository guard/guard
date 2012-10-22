module Guard
  class Interactor

    CHANGE = Pry::CommandSet.new do
      create_command 'change' do

        group 'Guard'
        description 'Trigger a file change.'

        banner <<-BANNER
          Usage: change <scope>

          Runs the Guard plugin `run_on_changes` action.

          You may want to specify an optional scope to the action,
          either the name of a Guard plugin or a plugin group.
        BANNER

        def process(*entries)
          scopes, rest = ::Guard::Interactor.convert_scope(entries)

          if rest.length != 0
            ::Guard.within_preserved_state do
              ::Guard.runner.run_on_changes(rest, [], [])
            end
          else
            output.puts 'Please specify a file.'
          end
        end

      end
    end

  end
end

Pry.commands.import ::Guard::Interactor::CHANGE
