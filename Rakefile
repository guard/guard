require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec

require 'guard/rake_task'
Guard::RakeTask.new(:guard, '--plugin ronn')

namespace :release do
  require 'guard/version'

  desc "Push Guard #{Guard::VERSION} to RubyGems and publish its GitHub release"
  task full: ['release:gem', 'release:github']

  desc "Push Guard #{Guard::VERSION} to RubyGems"
  task :gem do
    input = ''
    begin
      puts "Release Guard #{Guard::VERSION} to RubyGems? (y/n)"
      input = STDIN.gets.chomp.downcase
    end while !%w[y n].include?(input)

    exit if input == 'n'

    Rake::Task['release'].invoke
  end

  desc "Publish Guard #{Guard::VERSION} GitHub release"
  task :github do
    require 'gems'
    if Guard::VERSION != Gems.info('guard')['version']
      puts "Guard #{Guard::VERSION} is not yet released."
      puts "Please release it first with: rake release:gem"
      exit
    end

    tags = `git ls-remote --tags origin`.split("\n")
    unless tags.find { |tag| tag =~ /v#{Guard::VERSION}$/ }
      puts "The tag v#{Guard::VERSION} has not yet been pushed."
      puts "Please push it first with: rake release:gem"
      exit
    end

    require 'octokit'
    gh_client = Octokit::Client.new(netrc: true)
    gh_releases = gh_client.releases('guard/guard')
    tag_name = "v#{Guard::VERSION}"

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

      if gh_client.update_release(gh_release.url, draft: false)
        puts "GitHub release #{tag_name} has been published!"
      else
        puts "GitHub release #{tag_name} couldn't be published!"
      end
    end
  end
end
