module Guard
  class Dsl
    class << self
      @@options = nil

      def evaluate_guardfile(options = {})
        options.is_a?(Hash) or raise ArgumentError.new("evaluate_guardfile not passed a Hash!")

        @@options = options.dup
        instance_eval_guardfile(fetch_guardfile_contents)

        UI.error "No guards found in Guardfile, please add at least one." if !::Guard.guards.nil? && ::Guard.guards.empty?
      end

      def reevaluate_guardfile
        ::Guard.guards.clear
        @@options.delete(:guardfile_contents)
        Dsl.evaluate_guardfile(@@options)
        msg = "Guardfile has been re-evaluated."
        UI.info(msg)
        Notifier.notify(msg)
      end

      def instance_eval_guardfile(contents)
        begin
          new.instance_eval(contents, @@options[:guardfile_path], 1)
        rescue
          UI.error "Invalid Guardfile, original error is:\n#{$!}"
          exit 1
        end
      end

      def guardfile_include?(guard_name)
        guardfile_contents.match(/^guard\s*\(?\s*['":]#{guard_name}['"]?/)
      end

      def read_guardfile(guardfile_path)
        begin
          @@options[:guardfile_path]     = guardfile_path
          @@options[:guardfile_contents] = File.read(guardfile_path)
        rescue
          UI.error("Error reading file #{guardfile_path}")
          exit 1
        end
      end

      def fetch_guardfile_contents
        # TODO: do we need .rc file interaction?
        if @@options[:guardfile_contents]
          UI.info "Using inline Guardfile."
          @@options[:guardfile_path] = 'Inline Guardfile'

        elsif @@options[:guardfile]
          if File.exist?(@@options[:guardfile])
            read_guardfile(@@options[:guardfile])
            UI.info "Using Guardfile at #{@@options[:guardfile]}."
          else
            UI.error "No Guardfile exists at #{@@options[:guardfile]}."
            exit 1
          end

        else
          if File.exist?(guardfile_default_path)
            read_guardfile(guardfile_default_path)
          else
            UI.error "No Guardfile found, please create one with `guard init`."
            exit 1
          end
        end

        unless guardfile_contents_usable?
          UI.error "The command file(#{@@options[:guardfile]}) seems to be empty."
          exit 1
        end

        guardfile_contents
      end

      def guardfile_contents
        @@options ? @@options[:guardfile_contents] : ""
      end

      def guardfile_path
        @@options ? @@options[:guardfile_path] : ""
      end

      def guardfile_contents_usable?
        guardfile_contents && guardfile_contents.size >= 'guard :a'.size # smallest guard-definition
      end

      def guardfile_default_path
        File.exist?(local_guardfile_path) ? local_guardfile_path : home_guardfile_path
      end

    private

      def local_guardfile_path
        File.join(Dir.pwd, "Guardfile")
      end

      def home_guardfile_path
        File.expand_path(File.join("~", ".Guardfile"))
      end

    end

    def group(name, &guard_definition)
      @groups = @@options[:group] || []
      guard_definition.call if guard_definition && (@groups.empty? || @groups.map(&:to_sym).include?(name.to_sym))
    end

    def guard(name, options = {}, &watch_definition)
      @watchers = []
      watch_definition.call if watch_definition
      ::Guard.add_guard(name.to_sym, @watchers, @guard_options)
    end

    def watch(pattern, &action)
      @watchers << ::Guard::Watcher.new(pattern, action)
    end

  end
end
