# frozen_string_literal: true

require "digest"
require "faraday"
require "jwt"
require "net/http"
require "uri"
require "warden"

require "hibiscus/config"
require "hibiscus/engine"
require "hibiscus/errors"
require "hibiscus/jwks"
require "hibiscus/metadata"
require "hibiscus/strategy"
require "hibiscus/version"

# Easy openid authentication for your rails application.
module Hibiscus
  class << self
    # Register an openid provider that will be used for authentication. The block you pass to this method will be used
    # to find the user. It will recieve the claims from the openid provider as an argument. You should return the user
    # that will be logged in from this block. If you return nil no user will be logged in and authentication will fail.
    #
    # @param identifier [Symbol] the label for the provider.
    # @param client_id [String] the id to be used for the openid provider.
    # @param client_secret [String] the secret to be used for the openid provider.
    # @param metadata_url [String] the url to download the metadata for the openid provider.
    #
    # @example
    #   options = { client_id: "id", client_secret: "secret", metadata_url: "https://test.com/metadata" }
    #   Hibiscus.register_provider(:test, **options) do |claims|
    #     User.find_by(email: claims[:email])
    #   end
    def register_provider(identifier, client_id:, client_secret:, metadata_url:, &user_finder)
      raise ArgumentError, "You must supply a block" unless block_given?

      openid_config = Config.new(client_id:, client_secret:, metadata_url:, user_finder:)

      strategy = Class.new(Strategy) do
        self.openid_config = openid_config
      end

      Warden::Strategies.add(identifier.to_sym, strategy)
    end
  end
end
