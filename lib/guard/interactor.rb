module Guard
  module Interactor
    
    def self.init_signal_traps
      # Run all (Ctrl-\)
      Signal.trap('QUIT') do
        ::Guard.run do
          ::Guard.guards.each(&:run_all)
        end
      end
      
      # Stop (Ctrl-C)
      Signal.trap('INT') do
        ::Guard.listener.stop
        if ::Guard.guards.all?(&:stop)
          UI.info "Bye bye...", :reset => true
          abort("\n")
        else
          ::Guard.listener.start
        end
      end
      
      # Reload (Ctrl-Z)
      Signal.trap('TSTP') do
        ::Guard.run do
          ::Guard.guards.each(&:reload)
        end
      end
    end
    
  end
end