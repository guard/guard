source 'https://rubygems.org'

gemspec

gem 'rake'

group :development, :test do
  # This plugin is required in the tests!
  gem 'guard-rspec', require: false
  gem 'guard-ronn', require: false
end

# The development group will no be
# installed on Travis CI.
#
group :development do
  gem 'yard'
  gem 'redcarpet'
  gem 'pimpmychangelog'

  require 'rbconfig'

  if RbConfig::CONFIG['target_os'] =~ /darwin/i
    gem 'ruby_gntp', require: false

  elsif RbConfig::CONFIG['target_os'] =~ /linux/i
    gem 'libnotify', require: false

  elsif RbConfig::CONFIG['target_os'] =~ /mswin|mingw/i
    gem 'win32console', require: false
    gem 'rb-notifu', require: false
  end
end

# The test group will be
# installed on Travis CI
#
group :test do
  gem 'rspec', '~> 2.14'
  gem 'coveralls', require: false
end
