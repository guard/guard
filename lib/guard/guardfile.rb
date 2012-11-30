module Guard

  # The Guardfile is responsible for generating the Guardfile
  # and adding guards' template into it.
  #
  # @see Guard::CLI
  #
  class Guardfile

    require 'guard'
    require 'guard/ui'

    class << self

      # Creates the initial Guardfile template when it does not
      # already exist.
      #
      # @see Guard::CLI.init
      #
      # @param [Hash] options The options for creating a Guardfile
      # @option options [Boolean] :abort_on_existence Whether to abort or not when a Guardfile already exists
      #
      def create_guardfile(options = {})
        if !File.exist?('Guardfile')
          ::Guard::UI.info "Writing new Guardfile to #{ Dir.pwd }/Guardfile"
          FileUtils.cp(GUARDFILE_TEMPLATE, 'Guardfile')
        elsif options[:abort_on_existence]
          ::Guard::UI.error "Guardfile already exists at #{ Dir.pwd }/Guardfile"
          abort
        end
      end

      # Opens an existing guardfile and searches for redundant definitions
      # if extraneous defintions are found, it warns the user
      #
      # @see Guard::CLI.init
      #
      # @param [String] class name of gem definition that you would like to search for in the Guardfile
      # @param [String] contents of existing guardfile
      #
      def duplicate_definitions?(guard_class, guard_file)
        matches = guard_file.to_s.scan(/guard\s[\'|\"]#{guard_class}[\'|\"]\sdo/)
        if matches.count > 1
          ::Guard::UI.info "There are #{matches.count.to_s} definitions in your Guardfile for '#{guard_class}', you may want to clean up your Guardfile as this could cause issues."
          return true
        else
          return false
        end
      end

      # Adds the Guardfile template of a Guard implementation
      # to an existing Guardfile.
      #
      # @see Guard::CLI.init
      #
      # @param [String] guard_name the name of the Guard or template to initialize
      #
      def initialize_template(guard_name)
        guard_class = ::Guard.get_guard_class(guard_name, true)

        if guard_class
          guard_class.init(guard_name)
          guardfile_name = 'Guardfile'
          guard_file = File.read(guardfile_name) if File.exists?(guardfile_name)
          duplicate_definitions?(guard_name, guard_file)
        elsif File.exist?(File.join(HOME_TEMPLATES, guard_name))
          content  = File.read('Guardfile')
          template = File.read(File.join(HOME_TEMPLATES, guard_name))

          File.open('Guardfile', 'wb') do |f|
            f.puts(content)
            f.puts('')
            f.puts(template)
          end

          ::Guard::UI.info "#{ guard_name } template added to Guardfile, feel free to edit it"
        else
          const_name = guard_name.downcase.gsub('-', '')
          UI.error "Could not load 'guard/#{ guard_name.downcase }' or '~/.guard/templates/#{ guard_name.downcase }' or find class Guard::#{ const_name.capitalize }"
        end
      end

      # Adds the templates of all installed Guard implementations
      # to an existing Guardfile.
      #
      # @see Guard::CLI.init
      #
      def initialize_all_templates
        ::Guard.guard_gem_names.each { |g| initialize_template(g) }
      end

    end
  end
end
