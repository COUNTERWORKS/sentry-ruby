require "spec_helper"

RSpec.describe Sentry::SolidQueue::Configuration do
  it "initializes without error" do
    expect { described_class.new }.not_to raise_error
  end
end
