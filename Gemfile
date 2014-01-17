source 'https://rubygems.org'

gemspec

gem 'rake'

group :development, :test do
  # This plugin is required in the tests!
  gem 'guard-rspec', require: false
end

# The development group will no be
# installed on Travis CI.
#
group :development do
  gem 'yard', require: false
  gem 'redcarpet', require: false
  gem 'guard-ronn', require: false

  # Used for release
  gem 'gems', require: false
  gem 'netrc', require: false
  gem 'octokit', require: false

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
  gem 'coveralls', require: false
end
