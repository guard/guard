module Guard
  class Dsl

    class << self
      attr_accessor :options

      def evaluate_guardfile(options = {})
        self.options = options

        guardfile = "#{Dir.pwd}/Guardfile"
        if File.exists?(guardfile)
          begin
            new.instance_eval(File.read(guardfile.to_s), guardfile.to_s, 1)
          rescue
            UI.error "Invalid Guardfile, original error is:\n#{$!}"
            exit 1
          end
        else
          UI.error "No Guardfile in current folder, please create one."
          exit 1
        end
      end

      def guardfile_included?(guard_name)
        File.read('Guardfile').include?("guard '#{guard_name}'")
      end
    end

    def group(name, &definition)
      options = self.class.options
      definition.call if definition && (options[:group].empty? || options[:group].include?(name))
    end

    def guard(name, options = {}, &definition)
      @watchers = []
      definition.call if definition
      ::Guard.add_guard(name, @watchers, options)
    end
    
    def watch(pattern, &action)
      @watchers << ::Guard::Watcher.new(pattern, action)
    end
    
  end
end
