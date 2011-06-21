require 'thor'
require 'guard/version'

module Guard
  class CLI < Thor
    default_task :start

    method_option :clear,  :type => :boolean, :default => false, :aliases => '-c', :banner => "Auto clear shell before each change/run_all/reload"
    method_option :notify, :type => :boolean, :default => true,  :aliases => '-n', :banner => "Notifications feature (growl/libnotify)"
    method_option :debug,  :type => :boolean, :default => false, :aliases => '-d', :banner => "Print debug messages"
    method_option :group,  :type => :array,   :default => [],    :aliases => '-g', :banner => "Run only the passed groups"

    desc "start", "Starts Guard"
    def start
      ::Guard.start(options)
    end

    desc "version", "Prints Guard's version"
    def version
      ::Guard::UI.info "Guard version #{Guard::VERSION}"
    end
    map %w(-v --version) => :version

    desc "init [GUARD]", "Generates a Guardfile into the current working directory, or insert the given GUARD in an existing Guardfile"
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

    desc "show", "Show all defined Guards and their options"
    def show
      ::Guard::DslDescriber.evaluate_guardfile(options)

      ::Guard::DslDescriber.guardfile_structure.each do |group|
        if !group[:guards].empty?
          if group[:group]
            puts "Group #{group[:group]}:"
          else
            puts "(Global):"
          end

          group[:guards].each do |guard|
            print "  #{guard[:name]}"

            if !guard[:options].empty?
              print ": #{guard[:options].collect { |k, v| "#{k} => #{v}" }.join(", ")}"
            end
            puts
          end
        end
      end

      puts
    end
    map %w(-T) => :show
  end
end
