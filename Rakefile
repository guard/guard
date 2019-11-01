# frozen_string_literal: true

require "nenv"
require "bundler/gem_tasks"

require "tasks/releaser"

default_tasks = []

require "rspec/core/rake_task"
default_tasks << RSpec::Core::RakeTask.new(:spec) do |t|
  t.verbose = Nenv.ci?
end

require "guard/rake_task"

unless defined?(JRUBY_VERSION)
  Guard::RakeTask.new(:guard, "--plugin ronn")
end

require "cucumber/rake/task"
Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
  t.profile = Nenv.ci? ? "guard" : "travis"
end
default_tasks << Struct.new(:name).new(:features)

unless Nenv.ci?
  require "rubocop/rake_task"
  default_tasks << RuboCop::RakeTask.new(:rubocop)
end

task default: default_tasks.map(&:name)

# Coveralls:
#
# TODO: uncomment to merge results from RSpec and Cucumber
# require "coveralls/rake/task"
# Coveralls::RakeTask.new
# task :default => [:spec, :features, 'coveralls:push']
#
# TODO: for the above to work, also change Coveralls.wear_merged! instead of
# wear! in spec/spec_helper.rb

PROJECT_NAME = "Guard"
CURRENT_VERSION = Guard::VERSION

class GuardReleaser
  def self.releaser
    @releaser ||= Releaser.new(
      project_name: PROJECT_NAME,
      gem_name: "guard",
      github_repo: "guard/guard",
      version: CURRENT_VERSION
    )
  end
end

namespace :release do
  desc "Push #{PROJECT_NAME} #{CURRENT_VERSION} to RubyGems and publish"\
    " its GitHub release"

  task full: ["release:gem", "release:github"]

  desc "Push #{PROJECT_NAME} #{CURRENT_VERSION} to RubyGems"
  task :gem do
    GuardReleaser.releaser.rubygems
  end

  desc "Publish #{PROJECT_NAME} #{CURRENT_VERSION} GitHub release"
  task :github do
    GuardReleaser.releaser.github
  end
end
