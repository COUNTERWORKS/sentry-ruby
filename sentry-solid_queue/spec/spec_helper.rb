require "bundler/setup"
require "active_job"
require "active_record"
require "active_model"
require "rails"
require "solid_queue"
require "sentry-solid_queue"
require "rspec"


require "sentry/test_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include(Sentry::TestHelper)

  config.after :each do
    reset_sentry_globals!
  end
end

def perform_basic_setup
  Sentry.init do |config|
    config.dsn = 'http://12345:67890@sentry.localdomain/sentry/42'
    config.background_worker_threads = 0
    config.transport.transport_class = Sentry::DummyTransport
    yield config if block_given?
  end
end
