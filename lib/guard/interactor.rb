module Guard
  module Interactor
    extend self

    def run_all
      ::Guard.run do
        ::Guard.guards.each { |guard| ::Guard.supervised_task(guard, :run_all) }
      end
    end

    def stop
      UI.info "Bye bye...", :reset => true
      ::Guard.listener.stop
      ::Guard.guards.each { |guard| ::Guard.supervised_task(guard, :stop) }
      abort("\n")
    end

    def reload
      ::Guard.run do
        ::Guard.guards.each { |guard| ::Guard.supervised_task(guard, :reload) }
      end
    end

    def self.init_signal_traps
      # Run all (Ctrl-\)
      Signal.trap('QUIT') do
        run_all
      end

      # Stop (Ctrl-C)
      Signal.trap('INT') do
        stop
      end

      # Reload (Ctrl-Z)
      Signal.trap('TSTP') do
        reload
      end
    end
  end
end
