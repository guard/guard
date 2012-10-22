require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

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
      %w(1.8.7 1.9.2 1.9.3 jruby ree rbx).each do |version|
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
