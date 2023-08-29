# frozen_string_literal: true

module Hibiscus
  # @api private
  class Metadata
    attr_reader :cache_key, :metadata_url

    def initialize(metadata_url)
      @metadata_url = metadata_url.dup.to_s.freeze
      @cache = Rails.cache
      @cache_key = "hibiscus/metadata/#{Digest::MD5.hexdigest(metadata_url)}".freeze

      freeze
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

    attr_reader :cache

    def config_document
      cache.fetch(cache_key) do
        client.get(metadata_url).body
      end
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
