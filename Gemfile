source "https://rubygems.org"

gemspec unless ENV["USE_INSTALLED_GUARD"] == "1"

gem "rake"

# The development group will not be
# installed on Travis CI.

group :development do

  gem "rubocop", "~> 0.26.1", require: false
  gem "guard-rubocop", require: false

  gem "yard", require: false, platform: :mri
  gem "redcarpet", require: false, platform: :mri
  gem "guard-ronn", require: false, platform: :mri

  # Used for release
  gem "gems", require: false, platform: :mri
  gem "netrc", require: false, platform: :mri
  gem "octokit", require: false, platform: :mri
end

# The test group will be
# installed on Travis CI
#
group :test do
  # Both guard-rspec and guard-cucumber are used by cucumber features
  gem "guard-cucumber", require: false
  gem "guard-rspec", require: false

  gem "codeclimate-test-reporter", require: nil
  gem "rspec", ">= 3.0.0", require: false
  gem "aruba", require: false
end

# Needed for Travis
# See http://docs.travis-ci.com/user/languages/ruby/#Rubinius
#
platforms :rbx do
  gem "racc"
  gem "rubysl", "~> 2.0"
  gem "psych"
  gem "json"
  gem "rubinius-coverage"
end
