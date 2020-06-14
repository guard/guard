# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)
require "guard/version"

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name = "guard"
  s.version = Guard::VERSION
  s.platform = Gem::Platform::RUBY
  s.license = "MIT"
  s.authors = ["Thibaud Guillaume-Gentil"]
  s.email = ["thibaud@thibaud.gg"]
  s.homepage = "http://guardgem.org"
  s.summary = "Guard keeps an eye on your file modifications"
  s.description = "Guard is a command line tool to easily handle events"\
    " on file system modifications."

  s.required_ruby_version = ">= 2.5.5"

  s.add_runtime_dependency "formatador", ">= 0.2.4"
  s.add_runtime_dependency "listen", ">= 2.7", "< 4.0"
  s.add_runtime_dependency "lumberjack", ">= 1.0.12", "< 2.0"
  s.add_runtime_dependency "nenv", "~> 0.1"
  s.add_runtime_dependency "notiffany", "~> 0.0"
  s.add_runtime_dependency "pry", ">= 0.9.12"
  s.add_runtime_dependency "shellany", "~> 0.0"
  s.add_runtime_dependency "thor", ">= 0.18.1"

  git_files = `git ls-files -z`.split("\x0")
  files = git_files.select { |f| %r{^(?:bin|lib)/.*$} =~ f }
  files += %w(CHANGELOG.md LICENSE README.md)
  files += %w(man/guard.1 man/guard.1.html)

  # skip the large images/guard.png
  files += %w(images/pending.png images/failed.png images/success.png)

  s.files = files

  s.executables = %w[guard _guard-core]
  s.require_path = "lib"
end
