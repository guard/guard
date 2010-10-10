require 'thor'
require 'guard/version'

module Guard
  class CLI < Thor
    default_task :start
    
    desc "start", "Starts guard"
    method_option :clear, :type => :boolean, :default => false, :aliases => '-c', :banner => "Auto clear shell before each change/run_all/reload"
    method_option :debug, :type => :boolean, :default => false, :aliases => '-d', :banner => "Print debug messages"
    def start
      ::Guard.start(options)
    end
    
    desc "version", "Prints the guard's version information"
    def version
      ::Guard::UI.info "Guard version #{Guard::VERSION}"
    end
    map %w(-v --version) => :version
    
    desc "init [GUARD]", "Generates a Guardfile into the current working directory, or add it given guard"
    def init(guard_name = nil)
      if !File.exist?("Guardfile")
        puts "Writing new Guardfile to #{Dir.pwd}/Guardfile"
        FileUtils.cp(File.expand_path('../templates/Guardfile', __FILE__), 'Guardfile')
      elsif guard_name.nil?
        ::Guard::UI.error "Guardfile already exists at #{Dir.pwd}/Guardfile"
        exit 1
      end
      
      if guard_name
        guard_class = ::Guard.get_guard_class(guard_name)
        guard_class.init(guard_name)
      end
    end
    
  end
end