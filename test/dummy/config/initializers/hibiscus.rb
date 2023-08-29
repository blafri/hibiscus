# frozen_string_literal: true

options = {
  client_id: "test-id",
  client_secret: "secret",
  metadata_url: "https://openid-test.int/metadata"
}

Hibiscus.register_provider(:openid_test, **options) do |claims|
  claims[:name] if ["john"].include?(claims[:name])
end
