# frozen_string_literal: true

require_relative "lib/sentry/solid_queue/version"

Gem::Specification.new do |spec|
  spec.name          = "sentry-solid_queue"
  spec.version       = Sentry::SolidQueue::VERSION
  spec.authors       = ["Sentry Team"]
  spec.email         = ["accounts@sentry.io"]
  spec.summary       = "A gem that provides Solid Queue integration for the Sentry error logger"
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/getsentry/sentry-ruby"
  spec.license       = "MIT"


  spec.files = Dir["lib/**/*", "Rakefile", "README.md", "LICENSE.txt"]

  spec.add_dependency "sentry-ruby", "~> 6.2.0"
  spec.add_dependency "solid_queue", ">= 0.1" # Assuming 0.1+ for now
end
