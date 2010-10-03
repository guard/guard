module Guard
  class Dsl
    
    def self.evaluate_guardfile
      guardfile = "#{Dir.pwd}/Guardfile"
      dsl = new
      dsl.instance_eval(File.read(guardfile.to_s), guardfile.to_s, 1)
    rescue
      UI.error "Guardfile not found or invalid"
      exit 1
    end
    
    def guard(name, options = {}, &definition)
      @watchers = []
      definition.call
      Guard.add_guard(name, @watchers, options)
    end
    
    def watch(pattern, &action)
      @watchers << Guard::Watcher.new(pattern, action)
    end
    
  end
end
