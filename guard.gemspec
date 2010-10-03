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
  s.summary     = 'Guard keep an eye on your files event'
  s.description = 'Guard is a command line tool to easly manage script launch when your files change'
  
  s.rubyforge_project = 'guard'
  
  s.add_development_dependency  'bundler', '~> 1.0.1'
  s.add_development_dependency  'rspec',   '~> 2.0.0.beta.22'
  
  s.add_dependency 'thor',      '~> 0.14.2'
  s.add_dependency 'sys-uname', '~> 0.8.4'
  # Mac OS X
  s.add_dependency 'growl',     '~> 1.0.3'
  # Linux
  s.add_dependency 'rb-inotify'
  s.add_dependency 'libnotify', '~> 0.1.3'
  
  s.files        = Dir.glob('{bin,images,lib,ext}/**/*') + %w[LICENSE README.rdoc]
  s.extensions   = ['ext/extconf.rb']
  s.executable   = 'guard'
  s.require_path = 'lib'
end