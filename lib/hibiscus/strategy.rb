# frozen_string_literal: true

module Hibiscus
  # A warden strategy to authenicate the user via openid.
  # @api private
  class Strategy < Warden::Strategies::Base
    def initialize(...)
      super

      @provider_config = self.class.provider_config
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

    attr_reader :provider_config

    def validate_user
      fetch_token.then { |token| validate_token(token).first.transform_keys(&:to_sym) }
                 .then(&provider_config.user_finder)
    end

    def fetch_token
      token_fetch_params = {
        client_id: provider_config.client_id,
        code: params["code"],
        redirect_uri: request.url,
        grant_type: "authorization_code",
        client_secret: provider_config.client_secret
      }

      http_client.post(provider_config.token_endpoint, token_fetch_params).body.fetch(:id_token)
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
        iss: provider_config.issuer,
        verify_aud: true,
        aud: provider_config.client_id,
        jwks: jwks
      }

      JWT.decode(token, nil, true, decode_opts)
    rescue JWT::DecodeError, MetadataFetchError, JWKSFetchError => e
      authentication_error(e)
    end
    # rubocop:enable Metrics/MethodLength

    def jwks
      src = provider_config.jwks_uri
      cache_key = "hibiscus/jwks/#{src}"

      cache.fetch(cache_key, expires_in: 1.day, race_condition_ttl: 10.seconds) { http_client.get(src).body }
    rescue Faraday::Error => e
      raise JWKSFetchError, e
    end

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

    def logger
      Rails.logger
    end

    def cache
      Rails.cache
    end

    def http_client
      Faraday.new(request: { timeout: 5 }) do |f|
        f.request :url_encoded
        f.response :json, parser_options: { symbolize_names: true }
        f.response :raise_error
      end
    end
  end
end
