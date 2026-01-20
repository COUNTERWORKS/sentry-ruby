# frozen_string_literal: true

require "solid_queue"
require "sentry-ruby"
require "sentry/integrable"
require "sentry/solid_queue/version"
require "sentry/solid_queue/configuration"
require "sentry/solid_queue/error_handler"

require "sentry/solid_queue/patch"

module Sentry
  module SolidQueue
    extend Sentry::Integrable

    register_integration name: "solid_queue", version: Sentry::SolidQueue::VERSION

    if defined?(::Rails::Railtie)
      class Railtie < ::Rails::Railtie
        config.after_initialize do
          next unless Sentry.initialized?

          # Hook into SolidQueue's on_thread_error to capture background thread errors
          # (e.g. connection pool issues, polling errors) that aren't job execution errors.
          if defined?(::SolidQueue)
             original_handler = ::SolidQueue.on_thread_error

             ::SolidQueue.on_thread_error = -> (exception) do
               Sentry::SolidQueue::ErrorHandler.new.call(exception)
               original_handler&.call(exception)
             end
          end

          # Disable sentry-rails ActiveJob instrumentation for SolidQueue
          if defined?(::Sentry::Rails)
            Sentry.configuration.rails.skippable_job_adapters << "ActiveJob::QueueAdapters::SolidQueueAdapter"
          end

          # Apply our own instrumentation
          Sentry::SolidQueue::Patch.patch!
        end
      end
    end
  end
end
