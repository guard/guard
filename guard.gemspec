# encoding: utf-8
$:.push File.expand_path('../lib', __FILE__)
require 'guard/version'

Gem::Specification.new do |s|
  s.name        = 'guard'
  s.version     = Guard::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = 'MIT'
  s.authors     = ['Thibaud Guillaume-Gentil']
  s.email       = ['thibaud@thibaud.me']
  s.homepage    = 'http://guardgem.org'
  s.summary     = 'Guard keeps an eye on your file modifications'
  s.description = 'Guard is a command line tool to easily handle events on file system modifications.'

  s.add_runtime_dependency 'thor',       '>= 0.14.6'
  s.add_runtime_dependency 'listen',     '>= 2.0.0.beta.2'
  s.add_runtime_dependency 'pry',        '>= 0.9.10'
  s.add_runtime_dependency 'lumberjack', '>= 1.0.2'
  s.add_runtime_dependency 'formatador', '>= 0.2.4'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'rspec',   '>= 2.14.1'

  s.files        = Dir.glob('{bin,images,lib}/**/*') + %w[CHANGELOG.md LICENSE man/guard.1 man/guard.1.html README.md]
  s.executable   = 'guard'
  s.require_path = 'lib'
end
