require "spec_helper"
require "sentry/solid_queue/instrumentation"

RSpec.describe Sentry::SolidQueue::Instrumentation do
  let(:job_class) do
    Class.new do
      def self.name
        "MyJob"
      end

      # Mock ActiveJob callbacks
      def self.around_enqueue(&block)
        @around_enqueue_block = block
      end

      def self.around_perform(&block)
        @around_perform_block = block
      end

      def self.run_enqueue(job, block)
        @around_enqueue_block.call(job, block) if @around_enqueue_block
      end

      def self.run_perform(job, block)
        @around_perform_block.call(job, block) if @around_perform_block
      end

      def self.queue_adapter_name
        "solid_queue"
      end

      include Sentry::SolidQueue::Instrumentation
    end
  end

  let(:job_arguments) { [] }
  let(:job) do
    double(
      "Job",
      class: job_class,
      job_id: "job123",
      queue_name: "default",
      arguments: job_arguments,
      enqueued_at: Time.now - 1, # 1 second ago
      executions: 0
    )
  end

  let(:block) { double("Block", call: true) }

  before do
    perform_basic_setup do |config|
      config.traces_sample_rate = 1.0
    end
  end

  describe ".around_enqueue" do
    it "adds sentry context to arguments and starts a span" do
      Sentry.get_current_scope.set_user(id: 1)

      expect(Sentry).to receive(:with_child_span).with(
        op: "queue.publish",
        description: "MyJob"
      ).and_call_original

      job_class.run_enqueue(job, block)

      # Check arguments injection
      last_arg = job.arguments.last
      expect(last_arg).to have_key("_sentry_context")
      expect(last_arg["_sentry_context"]["user"]).to eq({ id: 1 })
      expect(last_arg["_sentry_context"]).to have_key("trace_propagation_headers")

      expect(block).to have_received(:call)
    end
  end

  describe ".around_perform" do
    before do
      # Simulate enriched arguments from around_enqueue
      job.arguments << {
        "_sentry_context" => {
          "user" => { "id" => 1 },
          "trace_propagation_headers" => {
            "sentry-trace" => "d4c73b374d6f44d8892f3e8f80211606-2ad312b67f9c4373-1",
            "baggage" => "456"
          }
        }
      }
    end

    it "starts a transaction with propagated trace" do
      expect(Sentry).to receive(:continue_trace).with(
        { "sentry-trace" => "d4c73b374d6f44d8892f3e8f80211606-2ad312b67f9c4373-1", "baggage" => "456" },
        anything
      ).and_call_original

      expect(Sentry).to receive(:start_transaction).and_call_original

      job_class.run_perform(job, block)

      expect(block).to have_received(:call)

      # Arguments should be cleaned
      expect(job.arguments).to be_empty

      events = Sentry.get_current_client.transport.events
      expect(events.count).to eq(1)
      expect(events.first.type).to eq("transaction")
      expect(events.first.contexts.dig(:trace, :op)).to eq("queue.process")
      expect(events.first.contexts.dig(:trace, :data, "messaging.message.receive.latency")).to be_a(Integer)
      expect(events.first.contexts.dig(:trace, :data)).not_to have_key("messaging.message.retry.count")
      expect(events.first.transaction).to eq("SolidQueue/MyJob")
      expect(events.first.contexts.dig(:trace, :status)).to eq("ok")
      expect(events.first.user).to eq({ "id" => 1 })
    end

    context "when job is retried" do
      before do
        allow(job).to receive(:executions).and_return(1)
      end

      it "sets retry count" do
        job_class.run_perform(job, block)

        events = Sentry.get_current_client.transport.events
        expect(events.count).to eq(1)
        expect(events.first.contexts.dig(:trace, :data, "messaging.message.retry.count")).to eq(1)
      end
    end

    it "captures exception" do
      # Ensure arguments are clean so no context extraction error
      job.arguments.clear

      allow(block).to receive(:call).and_raise("boom")

      expect do
        job_class.run_perform(job, block)
      end.to raise_error("boom")

      events = Sentry.get_current_client.transport.events
      # Transaction + Error
      expect(events.count).to eq(2)

      transaction = events.find { |e| e.type == "transaction" }
      expect(transaction.contexts.dig(:trace, :status)).to eq("internal_error")

      error_event = events.find { |e| e.is_a?(Sentry::ErrorEvent) }
      expect(error_event.exception.values.first.value).to match("boom")
      expect(error_event.exception.values.first.mechanism.type).to eq("solid_queue")
    end

    context "when adapter is not solid_queue" do
      before do
        allow(job_class).to receive(:queue_adapter_name).and_return("async")
      end

      it "does not instrument" do
        job_class.run_perform(job, block)
        expect(Sentry.get_current_client.transport.events).to be_empty
      end
    end
  end
end
