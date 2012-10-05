source :rubygems

gemspec

gem 'rake'
gem 'listen', :github => 'guard/listen'

# The development group will no be
# installed on Travis CI.
#
group :development do

  gem 'pry'

  gem 'guard-ronn'

  gem 'yard'
  gem 'redcarpet'

  platform :ruby_19 do
    gem 'coolline'
  end

  require 'rbconfig'

  if RbConfig::CONFIG['target_os'] =~ /darwin/i
    gem 'growl', :require => false
    gem 'rb-fsevent', :require => false

    if `uname`.strip == 'Darwin' && `sw_vers -productVersion`.strip >= '10.8'
      gem 'terminal-notifier-guard', '~> 1.5.3', :require => false
    end rescue Errno::ENOENT

  elsif RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'libnotify',  '~> 0.8.0', :require => false
    gem 'rb-inotify', :require => false

  elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    gem 'win32console', :require => false
    gem 'rb-notifu', '>= 0.0.4', :require => false
    gem 'wdm', :require => false
  end
end

# The test group will be
# installed on Travis CI
#
group :test do
  gem 'rspec'
  gem 'guard-rspec'
end
