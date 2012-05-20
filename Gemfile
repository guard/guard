source :rubygems

gemspec

gem 'rake'

# platform :ruby do
#   gem 'rb-readline'
# end

group :guard do
  gem 'guard-ronn'
end

require 'rbconfig'

if RbConfig::CONFIG['target_os'] =~ /darwin/i
  gem 'growl', :require => false
elsif RbConfig::CONFIG['target_os'] =~ /linux/i
  gem 'libnotify',  '~> 0.7.1', :require => false
elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
  gem 'win32console', :require => false
  gem 'rb-notifu', '>= 0.0.4', :require => false
end


gem 'listen', :github => 'guard/listen'
gem 'guard-rspec', :github => 'guard/guard-rspec', :branch => 'guard_1_1'

