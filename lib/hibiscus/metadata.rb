# frozen_string_literal: true

module Hibiscus
  # @api private
  class Metadata
    attr_reader :config, :cache, :cache_key

    def initialize(config, cache)
      @config = config
      @cache = cache
      @cache_key = "hibiscus/metadata/#{Digest::MD5.hexdigest(config.metadata_url)}"
    end

    def to_h
      config_document
    end

    def method_missing(name)
      config_document.fetch(name) { super }
    end

    def respond_to_missing?(name)
      return true if config_document.include?(name)

      super
    end

    private

    def config_document
      cache.fetch(cache_key, expires_in: 1.day, race_condition_ttl: 10.seconds) { fetch_metadata }
    end

    def fetch_metadata
      client.get(config.metadata_url).body
    rescue Faraday::Error => e
      raise MetadataFetchError, e
    end

    def client
      Faraday.new(request: { timeout: 5 }) do |f|
        f.response :json, parser_options: { symbolize_names: true }
        f.response :raise_error
      end
    end
  end
end
