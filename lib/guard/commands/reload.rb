module Guard
  class Interactor

    RELOAD = Pry::CommandSet.new do
      create_command 'reload' do

        group 'Guard'
        description 'Reload all plugins.'

        banner <<-BANNER
          Usage: reload <scope>

          Run the Guard plugin `reload` action.

          You may want to specify an optional scope to the action,
          either the name of a Guard plugin or a plugin group.
        BANNER

        def process(*entries)
          scopes, rest = ::Guard::Interactor.convert_scope(entries)

          if rest.empty?
            ::Guard.reload scopes
          else
            output.puts "Unknown scope #{ rest.join(', ') }"
          end
        end

      end
    end

  end
end

Pry.commands.import ::Guard::Interactor::RELOAD
