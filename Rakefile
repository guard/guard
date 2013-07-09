require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

require 'guard/rake_task'
Guard::RakeTask.new(:guard, '--plugin ronn')
