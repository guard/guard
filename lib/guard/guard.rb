module Guard

  # Main class that every Guard implementation must subclass.
  #
  # Guard will trigger the `start`, `stop`, `reload`, `run_all` and `run_on_change`
  # methods depending on user interaction and file modification.
  #
  # Each Guard should provide a template Guardfile located within the Gem
  # at `lib/guard/guard-name/templates/Guardfile`.
  #
  class Guard
    include Hook

    attr_accessor :watchers, :options, :group

    # Initialize a Guard.
    #
    # @param [Array<Guard::Watcher>] watchers the Guard file watchers
    # @param [Hash] options the custom Guard options.
    #
    def initialize(watchers = [], options = {})
      @group = options.delete(:group) || :default
      @watchers, @options = watchers, options
    end

    # Initialize the Guard. This will copy the Guardfile template inside the Guard gem.
    # The template Guardfile must be located within the Gem at `lib/guard/guard-name/templates/Guardfile`.
    #
    # @param [String] name the name of the Guard
    #
    def self.init(name)
      if ::Guard::Dsl.guardfile_include?(name)
        ::Guard::UI.info "Guardfile already includes #{ name } guard"
      else
        content = File.read('Guardfile')
        guard   = File.read("#{ ::Guard.locate_guard(name) }/lib/guard/#{ name }/templates/Guardfile")
        File.open('Guardfile', 'wb') do |f|
          f.puts(content)
          f.puts("")
          f.puts(guard)
        end
        ::Guard::UI.info "#{name} guard added to Guardfile, feel free to edit it"
      end
    end

    # Call once when Guard starts. Please override initialize method to init stuff.
    #
    # @return [Boolean] Whether the start action was successful or not
    #
    def start
      true
    end

    # Call once when Guard quit.
    #
    # @return [Boolean] Whether the stop action was successful or not
    #
    def stop
      true
    end

    # Should be used for "reload" (really!) actions like reloading passenger/spork/bundler/...
    #
    # @return [Boolean] Whether the reload action was successful or not
    #
    def reload
      true
    end

    # Should be used for long action like running all specs/tests/...
    #
    # @return [Boolean] Whether the run_all action was successful or not
    #
    def run_all
      true
    end

    # Will be triggered when a file change matched a watcher.
    #
    # @param [Array<String>] paths the changes files or paths
    # @return [Boolean] Whether the run_all action was successful or not
    #
    def run_on_change(paths)
      true
    end

    def run_on_deletion(paths)
      true
    end

  end
end
