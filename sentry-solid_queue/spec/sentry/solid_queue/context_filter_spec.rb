require "spec_helper"
require "sentry/solid_queue/context_filter"

RSpec.describe Sentry::SolidQueue::ContextFilter do
  let(:context) do
    {
      "job_class" => "MyJob",
      "job_id" => "123",
      "arguments" => ["arg1"],
      "queue_name" => "default"
    }
  end

  subject { described_class.new(context) }

  describe "#transaction_name" do
    it "returns SolidQueue/JobClass" do
      expect(subject.transaction_name).to eq("SolidQueue/MyJob")
    end
  end

  describe "#filtered" do
    it "returns the context duplicated" do
      expect(subject.filtered).to eq(context)
      expect(subject.filtered).not_to be(context)
    end
  end
end
