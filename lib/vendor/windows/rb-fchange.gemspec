# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rb-fchange/version"

Gem::Specification.new do |s|
  s.name        = %q{rb-fchange}
  s.version     = FChange::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["stereobooster"]
  s.date = %q{2011-05-15}
  s.description = %q{A Ruby wrapper for Windows Kernel functions for monitoring the specified directory or subtree}
  s.email = ["stereobooster@gmail.com"]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    "README.md",
    "Rakefile",
    "lib/rb-fchange.rb",
    "lib/rb-fchange/event.rb",
    "lib/rb-fchange/native.rb",
    "lib/rb-fchange/native/flags.rb",
    "lib/rb-fchange/notifier.rb",
    "lib/rb-fchange/watcher.rb",
    "rb-fchange.gemspec"
  ]
  s.homepage = %q{http://github.com/stereobooster/rb-fchange}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A Ruby wrapper for Windows Kernel functions for monitoring the specified directory or subtree}
  s.add_dependency 'ffi'
  s.add_development_dependency  'bundler'
  s.add_development_dependency  'rspec'
end
