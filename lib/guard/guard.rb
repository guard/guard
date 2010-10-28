require 'guard'

module Guard
  class Guard
    attr_accessor :watchers, :options
    
    def initialize(watchers = [], options = {})
      @watchers, @options = watchers, options
    end
    
    # Guardfile template needed inside guard gem
    def self.init(name)
      if ::Guard::Dsl.guardfile_included?(name)
        ::Guard.info "Guardfile already include #{name} guard"
      else
        content = File.read('Guardfile')
        guard   = File.read("#{::Guard.locate_guard(name)}/lib/guard/#{name}/templates/Guardfile")
        File.open('Guardfile', 'wb') do |f|
          f.puts content
          f.puts ""
          f.puts guard
        end
        ::Guard.info "#{name} guard added to Guardfile, feel free to edit it"
      end
    end
    
    def method_missing(method_name, *args)
      if ReportCenter::TYPES.include? method_name
        ::Guard.send(method_name, *args)
      else
        super
      end
    end
    
    # ================
    # = Guard method =
    # ================
    
    # Call once when guard starts
    # Please override initialize method to init stuff
    def start
      true
    end
    
    # Call once when guard quit
    def stop
      true
    end
    
    # Should be mainly used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    def reload
      true
    end
    
    # Should be principally used for long action like running all specs/tests/...
    def run_all
      true
    end
    
    def run_on_change(paths)
      true
    end
    
  end
end