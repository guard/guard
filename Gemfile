source :rubygems

gemspec

gem 'rake'

group :guard do
  gem 'guard-ronn'
end

require 'rbconfig'

if RbConfig::CONFIG['target_os'] =~ /darwin/i
  gem 'rb-fsevent', '>= 0.4.0', :require => false
  gem 'growl',      '~> 1.0.3', :require => false
elsif RbConfig::CONFIG['target_os'] =~ /linux/i
  gem 'rb-inotify', '>= 0.8.5', :require => false
  gem 'libnotify',  '~> 0.1.3', :require => false
elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
  gem 'win32console', :require => false
  gem 'rb-fchange', '>= 0.0.2', :require => false
  gem 'rb-notifu', '>= 0.0.4', :require => false
end
