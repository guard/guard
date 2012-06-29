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

  elsif RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'libnotify',  '~> 0.7.1', :require => false

  elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    gem 'win32console', :require => false
    gem 'rb-notifu', '>= 0.0.4', :require => false
  end
end

# The test group will be
# installed on Travis CI
#
group :test do
  gem 'rspec'
  gem 'guard-rspec'
end
