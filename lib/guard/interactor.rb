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
      abort
    end

    def reload
      ::Guard.run do
        ::Guard.guards.each { |guard| ::Guard.supervised_task(guard, :reload) }
      end
    end

    def self.init_signal_traps
      # Run all (Ctrl-\)
      if Signal.list.has_key?('QUIT')
        Signal.trap('QUIT') do
          run_all
        end
      else
        UI.info "Your system doesn't support QUIT signal, so Ctrl-\\ (Run all) won't work"
      end

      # Stop (Ctrl-C)
      if Signal.list.has_key?('INT')
        Signal.trap('INT') do
          stop
        end
      else
        UI.info "Your system doesn't support INT signal, so Ctrl-C (Stop) won't work"
      end

      # Reload (Ctrl-Z)
      if Signal.list.has_key?('TSTP')
        Signal.trap('TSTP') do
          reload
        end
      else
        UI.info "Your system doesn't support TSTP signal, so Ctrl-Z (Reload) won't work"
      end

    end
  end
end
