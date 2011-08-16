require 'thor'
require 'guard/version'

module Guard
  class CLI < Thor
    default_task :start

    method_option :clear,     :type => :boolean, :default => false, :aliases => '-c', :banner => "Auto clear shell before each change/run_all/reload"
    method_option :notify,    :type => :boolean, :default => true,  :aliases => '-n', :banner => "Notifications feature (growl/libnotify)"
    method_option :debug,     :type => :boolean, :default => false, :aliases => '-d', :banner => "Print debug messages"
    method_option :group,     :type => :array,   :default => [],    :aliases => '-g', :banner => "Run only the passed groups"
    method_option :watchdir,  :type => :string,                     :aliases => '-w', :banner => "Specify the directory to watch"
    method_option :guardfile, :type => :string,                     :aliases => '-G', :banner => "Specify a Guardfile"

    desc "start", "Starts Guard"
    def start
      ::Guard.start(options)
    end

    desc "list", "Lists guards that can be used with init"
    def list
      ::Guard::DslDescriber.evaluate_guardfile(options)
      installed = []
      ::Guard::DslDescriber.guardfile_structure.each do |group|
        group[:guards].each {|x| installed << x[:name]} if group[:guards]
      end

      ::Guard::UI.info "Available guards:"
      ::Guard::guard_gem_names.sort.each do |name|
        if installed.include? name
          ::Guard::UI.info "   #{name} *"
        else
          ::Guard::UI.info "   #{name}"
        end
      end
      ::Guard::UI.info ' '
      ::Guard::UI.info "See also https://github.com/guard/guard/wiki/List-of-available-Guards"
      ::Guard::UI.info "* denotes ones already in your Guardfile"
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
            ::Guard::UI.info "Group #{group[:group]}:"
          else
            ::Guard::UI.info "(global):"
          end

          group[:guards].each do |guard|
            line = "  #{guard[:name]}"

            if !guard[:options].empty?
              line += ": #{guard[:options].collect { |k, v| "#{k} => #{v.inspect}" }.join(", ")}"
            end
            ::Guard::UI.info line
          end
        end
      end

      ::Guard::UI.info ''
    end
    map %w(-T) => :show
  end
end
