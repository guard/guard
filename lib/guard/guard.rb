module Guard
  class Guard
    attr_accessor :watchers, :options
    
    def initialize(watchers = [], options = {})
      @watchers, @options = watchers, options
    end
    
    # Guardfile template needed inside guard gem
    def self.init(name)
      if ::Guard::Dsl.guardfile_included?(name)
        ::Guard::UI.info "Guardfile already include #{name} guard"
      else
        content = File.read('Guardfile')
        guard   = File.read("#{::Guard.locate_guard(name)}/lib/guard/#{name}/templates/Guardfile")
        File.open('Guardfile', 'wb') do |f|
          f.puts content
          f.puts ""
          f.puts guard
        end
        ::Guard::UI.info "#{name} guard added to Guardfile, feel free to edit it"
      end
    end
    
    # ================
    # = Guard method =
    # ================
    
    def start
      true
    end
    
    # Retrieve a true value if the instance successfuly stopped
    def stop
      true
    end
    
    def reload
      true
    end
    
    def run_all
      true
    end
    
    def run_on_change(paths)
      true
    end
    
  end
end