require "nenv"
require "bundler/gem_tasks"

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

class Releaser
  def initialize(options = {})
    @project_name = options.delete(:project_name) do
      fail "project_name is needed!"
    end

    @gem_name = options.delete(:gem_name) do
      fail "gem_name is needed!"
    end

    @github_repo = options.delete(:github_repo) do
      fail "github_repo is needed!"
    end

    @version = options.delete(:version) do
      fail "version is needed!"
    end
  end

  def full
    rubygems
    github
  end

  def rubygems
    begin
      STDOUT.puts "Release #{@project_name} #{@version} to RubyGems? (y/n)"
      input = STDIN.gets.chomp.downcase
    end while !%w(y n).include?(input)

    exit if input == "n"

    Rake::Task["release"].invoke
  end

  def github
    tag_name = "v#{@version}"

    require "gems"

    _verify_released
    _verify_tag_pushed

    require "octokit"
    gh_client = Octokit::Client.new(netrc: true)

    gh_release = _detect_gh_release(gh_client, tag_name, true)
    return unless gh_release

    STDOUT.puts "Draft release for #{tag_name}:\n"
    STDOUT.puts gh_release.body
    STDOUT.puts "\n-------------------------\n\n"

    _confirm_publish

    return unless _update_release(gh_client, gh_release, tag_name)

    gh_release = _detect_gh_release(gh_client, tag_name, false)

    _success_summary(gh_release, tag_name)
  end

  private

  def _verify_released
    if @version != Gems.info(@gem_name)["version"]
      STDOUT.puts "#{@project_name} #{@version} is not yet released."
      STDOUT.puts "Please release it first with: rake release:gem"
      exit
    end
  end

  def _verify_tag_pushed
    tags = `git ls-remote --tags origin`.split("\n")
    return if tags.detect { |tag| tag =~ /v#{@version}$/ }

    STDOUT.puts "The tag v#{@version} has not yet been pushed."
    STDOUT.puts "Please push it first with: rake release:gem"
    exit
  end

  def _success_summary(gh_release, tag_name)
    href = gh_release.rels[:html].href
    STDOUT.puts "GitHub release #{tag_name} has been published!"
    STDOUT.puts "\nPlease enjoy and spread the word!"
    STDOUT.puts "Lack of inspiration? Here's a tweet you could improve:\n\n"
    STDOUT.puts "Just released #{@project_name} #{@version}! #{href}"
  end

  def _detect_gh_release(gh_client, tag_name, draft)
    gh_releases = gh_client.releases(@github_repo)
    gh_releases.detect { |r| r.tag_name == tag_name && r.draft == draft }
  end

  def _confirm_publish
    begin
      STDOUT.puts "Would you like to publish this GitHub release now? (y/n)"
      input = STDIN.gets.chomp.downcase
    end while !%w(y n).include?(input)

    exit if input == "n"
  end

  def _update_release(gh_client, gh_release, tag_name)
    result = gh_client.update_release(gh_release.rels[:self].href, draft: false)
    return true if result
    STDOUT.puts "GitHub release #{tag_name} couldn't be published!"
    false
  end
end

PROJECT_NAME = "Guard"
CURRENT_VERSION = Guard::VERSION

def releaser
  $releaser ||= Releaser.new(
    project_name: PROJECT_NAME,
    gem_name: "guard",
    github_repo: "guard/guard",
    version: CURRENT_VERSION)
end

namespace :release do
  desc "Push #{PROJECT_NAME} #{CURRENT_VERSION} to RubyGems and publish"\
    " its GitHub release"

  task full: ["release:gem", "release:github"]

  desc "Push #{PROJECT_NAME} #{CURRENT_VERSION} to RubyGems"
  task :gem do
    releaser.rubygems
  end

  desc "Publish #{PROJECT_NAME} #{CURRENT_VERSION} GitHub release"
  task :github do
    releaser.github
  end
end
