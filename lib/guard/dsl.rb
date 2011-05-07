module Guard
  class Dsl
    class << self
      def evaluate_guardfile(options = {})
        options.is_a?(Hash) or raise ArgumentError.new("evaluate_guardfile not passed a hash")

        @@orig_options = options.dup.freeze
        @@options = {}
        @@groups = {}
        prep_guardfile_contents
        instance_eval_guardfile(guardfile_contents, actual_guardfile(), 1)
      end

      def instance_eval_guardfile(contents, path, line)
        begin
          new.instance_eval(contents, path, line)
        rescue
          UI.error "Invalid Guardfile, original error is:\n#{$!}"
          exit 1
        end
      end

      def guardfile_include?(guard_name, guardfile = guardfile_contents)
        guardfile.match(/^guard\s*\(?\s*['":]#{guard_name}['"]?/)
      end

      def read_guardfile(my_file)
        @@options[:actual_guardfile] = my_file
        @@options[:guardfile] = @@orig_options[:guardfile]
        begin
          @@options[:guardfile_contents] = File.read(my_file)
        rescue
          UI.error("Error reading file #{my_file}")
          exit 1
        end
      end

      def prep_guardfile_contents
        #todo do we need .rc file interaction?
        if @@orig_options.has_key?(:guardfile_contents)
          UI.info "Using options[:guardfile_contents] for Guardfile"
          @@options[:actual_guardfile] = 'options[:guardfile_contents]'
          @@options[:guardfile_contents] = @@orig_options[:guardfile_contents]
        elsif @@orig_options.has_key?(:guardfile)
          UI.info "Using -command Guardfile"
          if File.exist?(guardfile_file())
            read_guardfile(guardfile_file)
          else
            UI.error "No Guardfile exists at #{guardfile_file}.  Check your -command option"
            exit 1
          end
        else
          UI.info "Using Guardfile in current dir"
          if File.exist?(guardfile_default_path)
            read_guardfile(guardfile_default_path)
          else
            UI.error "No Guardfile in current folder, please create one."
            exit 1
          end
        end
        unless guardfile_contents_usable?
          UI.error "The command file(#{@@orig_options[:guardfile_file]}) seems to be empty."
          exit 1
        end
      end

      def guardfile_contents
        @@options[:guardfile_contents] || @@orig_options[:guardfile_contents]
      end

      def guardfile_file
        @@options[:guardfile] || @@orig_options[:guardfile]
      end

      def actual_guardfile
        @@options[:actual_guardfile] || @@orig_options[:actual_guardfile]
      end

      def guardfile_contents_usable?
        guardfile_contents && guardfile_contents.length > 0 #TODO maybe the min length of the smallest possible definition?
      end

      def guardfile_default_path
        File.join(Dir.pwd, 'Guardfile')
      end

      def parent_path
        @@options[:parent]
      end
    end 

    def group(name, &guard_definition)
      
      guard_definition.call if guard_definition && (@@orig_options[:group].empty? || @@orig_options[:group].include?(name))
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
