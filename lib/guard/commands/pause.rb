module Guard
  class Interactor

    PAUSE = Pry::CommandSet.new do
      create_command 'pause' do

        group 'Guard'
        description 'Toggles the file listener.'

        banner <<-BANNER
          Usage: pause

          Toggles the file listener on and off.

          When the file listener is paused, the default Guard Pry
          prompt will show the pause sign `[p]`.
        BANNER

        def process
          ::Guard.pause
        end
      end
    end

  end
end

Pry.commands.import ::Guard::Interactor::PAUSE
