module Guard
  class Dsl

    class << self
      def evaluate_guardfile(options = {})
        @@options = options
        
        if File.exists?(guardfile_path)
          begin
            new.instance_eval(File.read(guardfile_path), guardfile_path, 1)
          rescue
            UI.error "Invalid Guardfile, original error is:\n#{$!}"
            exit 1
          end
        else
          UI.error "No Guardfile in current folder, please create one."
          exit 1
        end
      end

      def guardfile_include?(guard_name)
        File.read(guardfile_path).match(/^guard\s*\(?\s*['":]#{guard_name}['"]?/)
      end
      
      def guardfile_path
        File.join(Dir.pwd, 'Guardfile')
      end
    end

    def group(name, &guard_definition)
      guard_definition.call if guard_definition && (@@options[:group].empty? || @@options[:group].include?(name))
    end

    def guard(name, options = {}, &watch_definition)
      @watchers = []
      watch_definition.call if watch_definition
      ::Guard.add_guard(name, @watchers, options)
    end

    def watch(pattern, &action)
      @watchers << ::Guard::Watcher.new(pattern, action)
    end

  end
end
