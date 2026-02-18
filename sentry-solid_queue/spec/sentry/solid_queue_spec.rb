require "spec_helper"

RSpec.describe Sentry::SolidQueue do
  it "registers solid_queue integration" do
    expect(Sentry.integrations["solid_queue"]).to eq({name: "sentry.ruby.solid_queue", version: Sentry::SolidQueue::VERSION})
  end

  describe "Configuration" do
    it "has a configuration class" do
      expect(Sentry::SolidQueue::Configuration).to be_a(Class)
    end
  end
end
