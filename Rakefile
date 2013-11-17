require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec

require 'guard/rake_task'
Guard::RakeTask.new(:guard, '--plugin ronn')

class Releaser

  def initialize(options = {})
    @project_name = options.delete(:project_name) { raise 'project_name is needed!' }
    @gem_name     = options.delete(:gem_name) { raise 'gem_name is needed!' }
    @github_repo  = options.delete(:github_repo) { raise 'github_repo is needed!' }
    @version      = options.delete(:version) { raise 'version is needed!' }
  end

  def full
    rubygems
    github
  end

  def rubygems
    input = ''
    begin
      puts "Release #{@project_name} #{@version} to RubyGems? (y/n)"
      input = STDIN.gets.chomp.downcase
    end while !%w[y n].include?(input)

    exit if input == 'n'

    Rake::Task['release'].invoke
  end

  def github
    require 'gems'

    if @version != Gems.info(@gem_name)['version']
      puts "#{@project_name} #{@version} is not yet released."
      puts "Please release it first with: rake release:gem"
      exit
    end

    tags = `git ls-remote --tags origin`.split("\n")
    unless tags.find { |tag| tag =~ /v#{@version}$/ }
      puts "The tag v#{@version} has not yet been pushed."
      puts "Please push it first with: rake release:gem"
      exit
    end

    require 'octokit'
    gh_client = Octokit::Client.new(netrc: true)
    gh_releases = gh_client.releases(@github_repo)
    tag_name = "v#{@version}"

    if gh_release = gh_releases.find { |r| r.tag_name == tag_name && r.draft == true }
      input = ''
      puts "Draft release for #{tag_name}:\n"
      puts gh_release.body
      puts "\n-------------------------\n\n"
      begin
        puts "Would you like to publish this GitHub release now? (y/n)"
        input = STDIN.gets.chomp.downcase
      end while !%w[y n].include?(input)

      exit if input == 'n'

      if gh_client.update_release(gh_release.rels[:self].href, draft: false)
        gh_release = gh_client.releases(@github_repo).find { |r| r.tag_name == tag_name && r.draft == false }
        puts "GitHub release #{tag_name} has been published!"
        puts "\nPlease enjoy and spread the word!"
        puts "Lack of inspiration? Here's a tweet you could improve:\n\n"
        puts "Just released #{@project_name} #{@version}! #{gh_release.rels[:html].href}"
      else
        puts "GitHub release #{tag_name} couldn't be published!"
      end
    end
  end

end

PROJECT_NAME = 'Guard'
CURRENT_VERSION = Guard::VERSION

def releaser
  $releaser ||= Releaser.new(project_name: PROJECT_NAME, gem_name: 'guard',
                             github_repo: 'guard/guard', version: CURRENT_VERSION)
end

namespace :release do
  desc "Push #{PROJECT_NAME} #{CURRENT_VERSION} to RubyGems and publish its GitHub release"
  task full: ['release:gem', 'release:github']

  desc "Push #{PROJECT_NAME} #{CURRENT_VERSION} to RubyGems"
  task :gem do
    releaser.rubygems
  end

  desc "Publish #{PROJECT_NAME} #{CURRENT_VERSION} GitHub release"
  task :github do
    releaser.github
  end
end
