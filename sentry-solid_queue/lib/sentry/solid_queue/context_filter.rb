# frozen_string_literal: true

module Sentry
  module SolidQueue
    class ContextFilter
      attr_reader :context

      def initialize(context)
        @context = context
      end

      def transaction_name
        "SolidQueue/#{context["class"]}"
      end

      def filtered
        filter_context(context)
      end

      private

      def filter_context(context)
        # ActiveJob arguments can be complex, Sentry usually expects primitives or simple hashes.
        # We might want to filter or format args here if needed.
        # For now, return as is, relying on Sentry's payload cleaning.
        context.dup
      end
    end
  end
end
