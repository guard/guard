source :rubygems

gemspec

gem 'rake'

group :guard do
  gem 'guard-ronn'
end

require 'rbconfig'

if RbConfig::CONFIG['target_os'] =~ /darwin/i
  gem 'growl',      '~> 1.0.3', :require => false
elsif RbConfig::CONFIG['target_os'] =~ /linux/i
  gem 'libnotify',  '~> 0.1.3', :require => false
elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
  gem 'win32console', :require => false
  gem 'rb-notifu', '>= 0.0.4', :require => false
end
