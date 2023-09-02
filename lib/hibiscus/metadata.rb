# frozen_string_literal: true

module Hibiscus
  # @api private
  class Metadata
    def initialize(metadata_url)
      cache_key = "hibiscus/metadata/#{metadata_url}"
      @metadata = Rails.cache
                       .fetch(cache_key) { http_client.get(metadata_url).body }
                       .dup
                       .freeze

      freeze
    rescue Faraday::Error => e
      raise MetadataFetchError, e
    end

    def to_h
      @metadata
    end

    def method_missing(name)
      @metadata.fetch(name) { super }
    end

    def respond_to_missing?(name)
      return true if @metadata.include?(name)

      super
    end

    private

    def http_client
      Faraday.new(request: { timeout: 5 }) do |f|
        f.response :json, parser_options: { symbolize_names: true }
        f.response :raise_error
      end
    end
  end
end
