# frozen_string_literal: true

require "faraday"
require "jwt"
require "warden"

require_relative "hibiscus/engine"
require_relative "hibiscus/provider_config"
require_relative "hibiscus/strategy"
require_relative "hibiscus/version"

# Easy openid authentication for your rails application.
module Hibiscus
  Error = Class.new(StandardError)
  MetadataFetchError = Class.new(Hibiscus::Error)
  JWKSFetchError = Class.new(Hibiscus::Error)
  InvalidStateError = Class.new(Hibiscus::Error)

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

      strategy = Class.new(Hibiscus::Strategy) do
        @provider_config = Hibiscus::ProviderConfig.new(client_id: client_id, client_secret: client_secret,
                                                        metadata_url: metadata_url, user_finder: user_finder)

        class << self
          attr_reader :provider_config
        end
      end

      Warden::Strategies.add(identifier.to_sym, strategy)
    end

    def rails_controller_helpers_for(provider:, warden_scope:)
      Module.new do
        extend ActiveSupport::Concern

        module_eval <<-METHODS, __FILE__, __LINE__ + 1
          # included do
          #   helper_method :user_signed_in?, :current_user
          # end
          included do
            helper_method :#{warden_scope}_signed_in?, :current_#{warden_scope}
          end

          # def authenticate_user!
          #   request.env["warden"].authenticate!(:azure, scope: :user)
          # end
          def authenticate_#{warden_scope}!
            request.env["warden"].authenticate!(:#{provider}, scope: :#{warden_scope})
          end

          # def user_signed_in?
          #   request.env["warden"].authenticated?(:user)
          # end
          def #{warden_scope}_signed_in?
            request.env["warden"].authenticated?(:#{warden_scope})
          end

          # def current_user
          #   request.env["warden"].user(:user)
          # end
          def current_#{warden_scope}
            request.env["warden"].user(:#{warden_scope})
          end
        METHODS
      end
    end
  end
end
