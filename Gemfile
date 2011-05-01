source "http://rubygems.org"

gemspec

require 'rbconfig'

if Config::CONFIG['host_os'] =~ /darwin/i
  gem 'rb-fsevent', '>= 0.3.9'
  gem 'growl',      '~> 1.0'
elsif Config::CONFIG['host_os'] =~ /linux/i
  gem 'rb-inotify', '>= 0.5.1'
  gem 'libnotify',  '~> 0.1'
end
