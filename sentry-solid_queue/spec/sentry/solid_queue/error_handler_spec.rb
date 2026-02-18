require "spec_helper"

RSpec.describe Sentry::SolidQueue::ErrorHandler do
  subject { described_class.new }

  let(:transport) do
    Sentry.get_current_client.transport
  end

  before do
    perform_basic_setup
  end

  describe "#call" do
    it "captures exception via Sentry" do
      exception = RuntimeError.new("boom")
      
      subject.call(exception)

      expect(transport.events.count).to eq(1)
      event = transport.events.first.to_h
      expect(event[:exception][:values][0][:type]).to eq("RuntimeError")
      expect(event[:exception][:values][0][:value]).to match("boom")
      expect(event[:exception][:values][0][:mechanism][:handled]).to eq(false)
      expect(event[:exception][:values][0][:mechanism][:type]).to eq("solid_queue")
    end

    it "captures exception with context (if supported in future)" do
      # Currently context is just passed but not used by the simple handler yet.
      # This test mainly ensures no crash when context is passed.
      exception = RuntimeError.new("boom context")
      context = { job_id: "123" }
      
      subject.call(exception, context)

      expect(transport.events.count).to eq(1)
      event = transport.events.first.to_h
      expect(event[:exception][:values][0][:value]).to match("boom context")
    end
  end
end
