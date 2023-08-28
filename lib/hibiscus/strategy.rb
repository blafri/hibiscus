# frozen_string_literal: true

module Hibiscus
  # A warden strategy to authenicate the user via openid.
  # @api private
  class Strategy < Warden::Strategies::Base
    attr_reader :cache, :metadata, :openid_config, :logger

    class << self
      attr_reader :openid_config

      private

      attr_writer :openid_config
    end

    def initialize(...)
      super

      @cache = Rails.cache
      @logger = Rails.logger
      @openid_config = self.class.openid_config
      @metadata = Metadata.new(openid_config, cache)
    end

    def valid?
      params.key?("code") || params.key?("error")
    end

    def authenticate!
      if params.key?("error")
        fail!(params["error_description"])
        return
      end

      user = catch(:authentication_failure) { validate_user }
      return fail!(nil) if user.nil?

      success!(user)
    end

    private

    def validate_user
      fetch_token.then { |token| validate_token(token).first.transform_keys(&:to_sym) }
                 .then(&openid_config.user_finder)
    end

    def fetch_token
      token_fetch_params = {
        client_id: openid_config.client_id,
        code: params["code"],
        redirect_uri: request.url,
        grant_type: "authorization_code",
        client_secret: openid_config.client_secret
      }

      client.post(metadata.token_endpoint, token_fetch_params).body[:id_token]
    rescue Faraday::Error, MetadataFetchError => e
      authentication_error(e)
    end

    # rubocop:disable Metrics/MethodLength
    def validate_token(token)
      decode_opts = {
        algorithm: "RS256",
        verify_expiration: true,
        verify_not_before: true,
        verify_iat: true,
        verify_iss: true,
        iss: metadata.issuer,
        verify_aud: true,
        aud: openid_config.client_id,
        jwks: JWKS.new(metadata.jwks_uri, cache).to_h
      }

      JWT.decode(token, nil, true, decode_opts)
    rescue JWT::DecodeError, MetadataFetchError, JWKSFetchError => e
      authentication_error(e)
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def authentication_error(error)
      case error
      when Faraday::Error
        logger.error("Hibiscus could not exchange the recieved code for a token -> #{error.message}")
      when Hibiscus::MetadataFetchError
        logger.error("Hibiscus encountered an error trying to fetch the metadata document -> #{error.message}")
      when JWT::DecodeError
        logger.error("Hibiscus encountered an error while decoding the recieved token -> #{error.message}")
      when Hibiscus::JWKSFetchError
        logger.error("Hibiscus could not fetch the providers JSON Web Key Set -> #{error.message}")
      end

      throw(:authentication_failure)
    end
    # rubocop:enable Metrics/MethodLength

    def client
      Faraday.new(request: { timeout: 5 }) do |f|
        f.request :url_encoded
        f.response :json, parser_options: { symbolize_names: true }
        f.response :raise_error
      end
    end
  end
end
