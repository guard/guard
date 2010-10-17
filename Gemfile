source "http://rubygems.org"

gemspec

require 'rbconfig'

if Config::CONFIG['target_os'] =~ /darwin/i
  gem 'rb-fsevent', '>= 0.3.2'
end
if Config::CONFIG['target_os'] =~ /linux/i
  gem 'rb-inotify', '>= 0.5.1'
end
