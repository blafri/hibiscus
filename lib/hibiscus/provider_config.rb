# frozen_string_literal: true

module Hibiscus
  # @api private
  class ProviderConfig
    attr_reader :client_id, :client_secret, :metadata, :user_finder

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def initialize(client_id:, client_secret:, metadata_url:, user_finder:)
      @client_id = client_id.dup.to_s.freeze
      @client_secret = client_secret.dup.to_s.freeze
      @user_finder = user_finder.dup.freeze

      http_client = Faraday.new(request: { timeout: 5 }) do |f|
        f.response :json
        f.response :raise_error
      end

      @metadata = http_client.get(metadata_url).body.transform_keys(&:to_sym).freeze

      freeze
    rescue Faraday::Error => e
      raise Hibiscus::MetadataFetchError, e
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def method_missing(name)
      metadata.fetch(name) { super }
    end

    def respond_to_missing?(name)
      return true if metadata.include?(name)

      super
    end
  end
end
