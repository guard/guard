require 'thor'
require 'guard/version'

module Guard
  class CLI < Thor
    default_task :start
    
    desc "start", "Starts guard"
    method_option :clear, :type => :boolean, :default => false, :aliases => '-c', :banner => "Auto clear shell after each change"
    def start
      Guard.start(options)
    end
    
    desc "version", "Prints the guard's version information"
    def version
      Guard::UI.info "Guard version #{Guard::VERSION}"
    end
    map %w(-v --version) => :version
  end
end