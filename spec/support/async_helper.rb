# frozen_string_literal: true

require "async"
require "async/condition"
require "async/rspec"

module AsyncTestHelpers
  def async_condition
    Async::Condition.new
  end

  def async_task(&block)
    Async::Task.current.async(&block)
  end
end

RSpec.configure do |config|
  config.include AsyncTestHelpers, :async

  config.around(:each, :async) do |example|
    Async do |task|
      example.run
    ensure
      task.stop
    end
  end
end
