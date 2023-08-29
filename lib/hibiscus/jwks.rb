# frozen_string_literal: true

module Hibiscus
  # @api private
  class JWKS
    attr_reader :src, :cache_key

    def initialize(src)
      @src = src
      @cache = Rails.cache
      @cache_key = "hibiscus/jwks/#{Digest::MD5.hexdigest(src)}"
    end

    def to_h
      cache.fetch(cache_key, expires_in: 1.day, race_condition_ttl: 10.seconds) do
        client.get(src).body
      end
    rescue Faraday::Error => e
      raise JWKSFetchError, e
    end

    private

    attr_reader :cache

    def client
      Faraday.new(request: { timeout: 5 }) do |f|
        f.response :json, parser_options: { symbolize_names: true }
        f.response :raise_error
      end
    end
  end
end
