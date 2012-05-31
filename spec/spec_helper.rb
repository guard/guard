require 'rubygems'
require 'guard'
require 'guard/guard'
require 'rspec'

ENV["GUARD_ENV"] = 'test'

Dir["#{File.expand_path('..', __FILE__)}/support/**/*.rb"].each { |f| require f }

puts "Please do not update/create files while tests are running."

RSpec.configure do |config|
  config.color_enabled = true

  config.filter_run :focus => true
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    @fixture_path = Pathname.new(File.expand_path('../fixtures/', __FILE__))
  end

  config.before(:all) do
    ::Guard::Notifier.send(:auto_detect_notification)

    @guard_notify = ENV['GUARD_NOTIFY']
    @guard_notifications = ::Guard::Notifier.notifications
  end

  config.after(:all) do
    ENV['GUARD_NOTIFY'] = @guard_notify
    ::Guard::Notifier.notifications = @guard_notifications
  end

end
