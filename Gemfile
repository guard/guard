source 'https://rubygems.org'

gemspec

gem 'rake'

group :development, :test do
  # This plugin is required in the tests!
  gem 'guard-rspec', require: false
  gem 'rspec', '~> 3.0.0'
end

# The development group will not be
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
end

# The test group will be
# installed on Travis CI
#
group :test do
  gem 'coveralls', require: false
end

# Needed for Travis
# See http://docs.travis-ci.com/user/languages/ruby/#Rubinius
#
platforms :rbx do
  gem 'racc'
  gem 'rubysl', '~> 2.0'
  gem 'psych'
  gem 'json'
  gem 'rubinius-coverage'
end
