source 'https://rubygems.org'

gemspec

gem 'rake'
gem 'listen', :github => 'guard/listen'

# The development group will no be
# installed on Travis CI.
#
group :development do
  gem 'guard-rspec'
  gem 'guard-ronn'
  gem 'yard'
  gem 'redcarpet'
  gem 'pimpmychangelog'

  require 'rbconfig'

  if RbConfig::CONFIG['target_os'] =~ /darwin/i
    gem 'ruby_gntp', :require => false

  elsif RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'libnotify', '~> 0.8.0', :require => false

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
  gem 'coveralls', :require => false
end
