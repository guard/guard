# -*- encoding: utf-8 -*-
$:.unshift File.expand_path("../lib", __FILE__)
require "guard/version"

Gem::Specification.new do |s|
  s.name        = 'guard'
  s.version     = Guard::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Thibaud Guillaume-Gentil']
  s.email       = ['thibaud@thibaud.me']
  s.homepage    = 'https://github.com/guard/guard'
  s.summary     = 'Guard keeps an eye on your file modifications'
  s.description = 'Guard is a command line tool to easily handle events on file system modifications.'

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project = 'guard'

  s.add_dependency 'thor',     '>= 0.14.6'
  s.add_dependency 'listen',   '>= 0.4.2'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rspec',       '~> 2.10.0'
  s.add_development_dependency 'guard-rspec', '~> 0.7.0'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'pry'

  s.files        = Dir.glob('{bin,images,lib}/**/*') + %w[CHANGELOG.md LICENSE man/guard.1 man/guard.1.html README.md]
  s.executable   = 'guard'
  s.require_path = 'lib'
end
