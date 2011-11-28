require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

namespace(:spec) do
  desc "Run all specs on multiple ruby versions (requires pik)"
  task(:portability) do
    %w[187 192 161].each do |version|
       system "cmd /c echo -----------#{version}------------ & " +
         "pik use #{version} & " +
         "bundle install & " +
         "rake spec"
    end
  end
end
