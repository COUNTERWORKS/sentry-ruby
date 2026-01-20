# frozen_string_literal: true

module Sentry
  class Configuration
    attr_reader :solid_queue

    add_post_initialization_callback do
      @solid_queue = Sentry::SolidQueue::Configuration.new
    end
  end

  module SolidQueue
    class Configuration
      # Set this option to true if you want Sentry to only capture the last job
      # retry if it fails.
      attr_accessor :report_after_job_retries

      def initialize
        @report_after_job_retries = false
      end
    end
  end
end
