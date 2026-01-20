# frozen_string_literal: true

require "sentry/solid_queue/instrumentation"

module Sentry
  module SolidQueue
    module Patch
      def self.patch!
        ActiveJob::Base.include(Sentry::SolidQueue::Instrumentation)
      end
    end
  end
end
