require 'bundler'
Bundler::GemHelper.install_tasks

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
           "bundle exec rake spec"
      end
    end
  else
    desc "Run all specs on multiple ruby versions (requires rvm)"
    task(:portability) do
      %w[1.8.7 1.9.2 ree].each do |version|
        system <<-BASH
          bash -c 'source ~/.rvm/scripts/rvm;
                   rvm #{version};
                   echo "--------- version #{version} ----------\n";
                   bundle install;
                   bundle exec rake spec'
        BASH
      end
    end
  end
end
