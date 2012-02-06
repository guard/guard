require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

desc "Build vendored gems"
task :build_vendor do
  raise unless File.exist?('Rakefile')
  # Destroy vendor
  sh "rm -rf lib/vendor && mkdir lib/vendor"

  # Clone the correct gems
  sh "git clone https://github.com/thibaudgg/rb-fsevent.git lib/vendor/darwin"
  sh "cd lib/vendor/darwin && git checkout 10c7980fa7b9678f787b7f4671f3b67f3a7571f1"
  sh "git clone https://github.com/nex3/rb-inotify.git lib/vendor/linux"
  sh "cd lib/vendor/linux && git checkout 01e7487e7a8d8f26b13c6835a321390c6618ccb7"
  sh "git clone https://github.com/stereobooster/rb-fchange.git lib/vendor/windows"
  sh "cd lib/vendor/windows && git checkout d655a602b73f11e6cca986cc3f9fe2846f2dc771"

  # Strip out the .git directories
  %w[darwin linux windows].each {|platform| sh "rm -rf lib/vendor/#{platform}/.git"}

  # Move ext directory of darwin to root
  sh "mkdir -p ext"
  sh "cp -r lib/vendor/darwin/ext/* ext/"

  # Alter darwin extconf.rb
  extconf_path = File.expand_path("../ext/extconf.rb", __FILE__)
  extconf_contents = File.read(extconf_path)
  extconf_contents.sub!(/puts "Warning/, '#\0')
  extconf_contents.gsub!(/bin\/fsevent_watch/, 'bin/fsevent_watch_guard')
  File.open(extconf_path, 'w') { |f| f << extconf_contents }

  # Alter lib/vendor/darwin/lib/rb-fsevent/fsevent.rb
  fsevent_path = File.expand_path("../lib/vendor/darwin/lib/rb-fsevent/fsevent.rb", __FILE__)
  fsevent_contents = File.read(fsevent_path)
  fsevent_contents.sub!(/fsevent_watch/, 'fsevent_watch_guard')
  fsevent_contents.sub!(/'\.\.'/, "'..', '..', '..', '..'")

  File.open(fsevent_path, 'w') { |f| f << fsevent_contents }
end

desc "Compile mac executable"
task :build_mac_exec do
  Dir.chdir(File.expand_path("../ext", __FILE__)) do
    system("ruby extconf.rb") or raise
  end
end

require 'rbconfig'
namespace(:spec) do
  if RbConfig::CONFIG['host_os'] =~ /mswin|mingw/i
    desc "Run all specs on multiple ruby versions (requires pik)"
    task(:portability) do
      %w[187 192 161].each do |version|
         system "cmd /c echo -----------#{version}------------ & " +
           "pik use #{version} & " +
           "bundle install & " +
           "bundle exec rspec spec"
      end
    end
  else
    desc "Run all specs on multiple ruby versions (requires rvm)"
    task(:portability) do
      Rake::Task[:build_mac_exec].invoke if RbConfig::CONFIG['host_os'] =~ /darwin(9|1\d)/i
      travis_config_file = File.expand_path("../.travis.yml", __FILE__)
      begin
        travis_options ||= YAML::load_file(travis_config_file)
      rescue => ex
        puts "Travis config file '#{travis_config_file}' could not be found: #{ex.message}"
        return
      end

      travis_options['rvm'].each do |version|
        system <<-BASH
          bash -c 'source ~/.rvm/scripts/rvm;
                   rvm #{version};
                   ruby_version_string_size=`ruby -v | wc -m`
                   echo;
                   for ((c=1; c<$ruby_version_string_size; c++)); do echo -n "="; done
                   echo;
                   echo "`ruby -v`";
                   for ((c=1; c<$ruby_version_string_size; c++)); do echo -n "="; done
                   echo;
                   RBXOPT="-Xrbc.db" bundle install;
                   RBXOPT="-Xrbc.db" bundle exec rspec spec -f doc 2>&1;'
        BASH
      end
    end
  end
end
