module Guard
  module Interactor
    
    def self.init_signal_traps
      # Run all (Ctrl-\)
      Signal.trap('QUIT') do
        ::Guard.run do
          ::Guard.guards.each { |guard| ::Guard.supervised_task(guard, :run_all) }
        end
      end
      
      # Stop (Ctrl-C)
      Signal.trap('INT') do
        UI.info "Bye bye...", :reset => true
        ::Guard.listener.stop
        ::Guard.guards.each { |guard| ::Guard.supervised_task(guard, :stop) }
        abort("\n")
      end
      
      # Reload (Ctrl-Z)
      Signal.trap('TSTP') do
        ::Guard.run do
          ::Guard.guards.each { |guard| ::Guard.supervised_task(guard, :reload) }
        end
      end
    end
    
  end
end