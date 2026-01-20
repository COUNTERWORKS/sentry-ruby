# frozen_string_literal: true

module Sentry
  module SolidQueue
    class ErrorHandler
      def call(exception, context = {})
        Sentry::SolidQueue.capture_exception(exception, hint: { background: false })
      end
    end
  end
end
