# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'guard/version'

Gem::Specification.new do |s|
  s.name        = 'guard'
  s.version     = Guard::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Thibaud Guillaume-Gentil']
  s.email       = ['thibaud@thibaud.me']
  s.homepage    = 'http://rubygems.org/gems/guard'
  s.summary     = 'Guard keep an eye on your files modifications.'
  s.description = 'Guard is a command line tool to easily handle events on files modifications.'

  s.required_rubygems_version = '>= 1.3.6'
  s.rubyforge_project = 'guard'

  s.add_development_dependency 'bundler',     '~> 1.0.7'
  s.add_development_dependency 'rspec',       '~> 2.5.0'
  s.add_development_dependency 'guard-rspec', '~> 0.2.0'

  s.add_dependency 'thor',     '~> 0.14.6'

  s.files        = Dir.glob('{bin,images,lib}/**/*') + %w[LICENSE README.rdoc]
  s.executable   = 'guard'
  s.require_path = 'lib'
end