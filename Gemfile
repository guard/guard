# frozen_string_literal: true

source 'https://rubygems.org'

gemspec unless ENV['USE_INSTALLED_GUARD'] == '1'

gem 'rake'

# The development group will not be
# installed on Travis CI.

group :development do
  # Force rubocop local runs to match HoundCI rubocop version
  # (https://github.com/houndci/linters/blob/master/Gemfile.lock).
  #
  # This needs to be manually updated until there's a resolution
  # on HoundCI's side.
  #
  # See https://github.com/houndci/hound/issues/1250
  gem 'rubocop', '0.54.0', require: false

  gem 'guard-rubocop', require: false

  gem 'guard-ronn', require: false, platform: :mri
  gem 'redcarpet', require: false, platform: :mri
  gem 'yard', require: false, platform: :mri

  # Used for release
  gem 'gems', require: false, platform: :mri
  gem 'netrc', require: false, platform: :mri
  gem 'octokit', require: false, platform: :mri
end

# The test group will be
# installed on Travis CI
#
group :test do
  # Both guard-rspec and guard-cucumber are used by cucumber features
  gem 'guard-cucumber', '~> 2.1', require: false
  gem 'guard-rspec', require: false

  gem 'aruba', '~> 0.9', require: false
  gem 'codeclimate-test-reporter', require: nil
  gem 'notiffany', '>= 0.0.6', require: false
  gem 'rspec', '>= 3.0.0', require: false
end

# Needed for Travis
# See http://docs.travis-ci.com/user/languages/ruby/#Rubinius
#
platforms :rbx do
  gem 'json'
  gem 'psych'
  gem 'racc'
  gem 'rubinius-coverage'
  gem 'rubysl', '~> 2.0'
end
