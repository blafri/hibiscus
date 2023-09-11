# frozen_string_literal: true

module Hibiscus
  Error = Class.new(StandardError)

  MetadataFetchError = Class.new(Hibiscus::Error)
  JWKSFetchError = Class.new(Hibiscus::Error)
  InvalidStateError = Class.new(Hibiscus::Error)
end
