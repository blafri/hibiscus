# frozen_string_literal: true

module Hibiscus
  # @api private
  class ProviderConfig
    attr_reader :client_id, :client_secret, :user_finder

    def initialize(client_id:, client_secret:, metadata_url:, user_finder:)
      @client_id = client_id.dup.to_s.freeze
      @client_secret = client_secret.dup.to_s.freeze
      @user_finder = user_finder.dup.freeze
      @metadata_url = metadata_url.dup.to_s.freeze
      @metadata_mutex = Mutex.new
      @jwks_mutex = Mutex.new
    end

    def jwks
      @jwks_mutex.synchronize do
        return @jwks unless jwks_stale?

        jwks_uri = metadata.fetch(:jwks_uri) { raise Hibiscus::Error, "jwks_uri not in metadata document" }
        result = http_client.get(jwks_uri)
        @jwks_stale_at = stale_at(result.headers)

        @jwks = result.body.freeze
      end
    rescue Faraday::Error => e
      raise JWKSFetchError, e
    end

    def method_missing(name)
      metadata.fetch(name) { super }
    end

    def respond_to_missing?(name)
      return true if metadata.include?(name)

      super
    end

    private

    def metadata
      @metadata_mutex.synchronize do
        return @metadata unless metadata_stale?

        result = http_client.get(@metadata_url)
        @metadata_stale_at = stale_at(result.headers)

        @metadata = result.body.freeze
      end
    rescue Faraday::Error => e
      raise Hibiscus::MetadataFetchError, e
    end

    def metadata_stale?
      return true if @metadata.nil?

      Time.now.to_i >= @metadata_stale_at
    end

    def jwks_stale?
      return true if @jwks.nil?

      Time.now.to_i >= @jwks_stale_at
    end

    def stale_at(headers)
      Time.now.to_i + headers.fetch("cache-control", "").slice(/max-age=(\d+)/i, 1).to_i
    end

    def http_client
      Faraday.new(request: { timeout: 5 }) do |f|
        f.response :json, parser_options: { symbolize_names: true }
        f.response :raise_error
      end
    end
  end
end
