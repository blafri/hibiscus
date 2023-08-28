# frozen_string_literal: true

module Hibiscus
  # Configuration value object.
  # @api private
  class Config
    attr_reader :client_id, :client_secret, :metadata_url, :user_finder

    def initialize(client_id:, client_secret:, metadata_url:, user_finder:)
      @client_id = client_id.dup.to_s.freeze
      @client_secret = client_secret.dup.to_s.freeze
      @metadata_url = metadata_url.dup.to_s.freeze
      @user_finder = user_finder.dup.freeze

      freeze
    end
  end
end
