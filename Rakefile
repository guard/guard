require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: [:spec, :features]

require "guard/rake_task"
Guard::RakeTask.new(:guard, "--plugin ronn")

require "cucumber/rake/task"

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format pretty"
end

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
    require "gems"

    if @version != Gems.info(@gem_name)["version"]
      STDOUT.puts "#{@project_name} #{@version} is not yet released."
      STDOUT.puts "Please release it first with: rake release:gem"
      exit
    end

    tags = `git ls-remote --tags origin`.split("\n")
    unless tags.detect { |tag| tag =~ /v#{@version}$/ }
      STDOUT.puts "The tag v#{@version} has not yet been pushed."
      STDOUT.puts "Please push it first with: rake release:gem"
      exit
    end

    require "octokit"
    gh_client = Octokit::Client.new(netrc: true)
    gh_releases = gh_client.releases(@github_repo)
    tag_name = "v#{@version}"

    gh_release = gh_releases.detect do |r|
      r.tag_name == tag_name && r.draft == true
    end

    return unless gh_releases

    STDOUT.puts "Draft release for #{tag_name}:\n"
    STDOUT.puts gh_release.body
    STDOUT.puts "\n-------------------------\n\n"
    begin
      STDOUT.puts "Would you like to publish this GitHub release now? (y/n)"
      input = STDIN.gets.chomp.downcase
    end while !%w(y n).include?(input)

    exit if input == "n"

    if gh_client.update_release(gh_release.rels[:self].href, draft: false)

      gh_release = gh_client.releases(@github_repo).detect do |r|
        r.tag_name == tag_name && r.draft == false
      end

      STDOUT.puts "GitHub release #{tag_name} has been published!"
      STDOUT.puts "\nPlease enjoy and spread the word!"
      STDOUT.puts "Lack of inspiration? Here's a tweet you could improve:\n\n"
      href = gh_release.rels[:html].href
      STDOUT.puts "Just released #{@project_name} #{@version}! #{href}"
    else
      STDOUT.puts "GitHub release #{tag_name} couldn't be published!"
    end
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
