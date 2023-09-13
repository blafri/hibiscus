# frozen_string_literal: true

require "test_helper"

module Hibiscus
  class StrategyTest < ActiveSupport::TestCase
    METADATA_URL = "https://openid-provider.int/metadata"
    private_constant :METADATA_URL

    JWKS_URL = "https://openid-provider.int/jwks"
    private_constant :JWKS_URL

    TOKEN_ENDPOINT = "https://openid-provider.int/token"
    private_constant :TOKEN_ENDPOINT

    test "#valid? returns false if code or error is not present in params" do
      env = Rack::MockRequest.env_for("http://localhost")

      assert_not(subject.new(env).valid?)
    end

    test "#valid? returns true when error is present in params" do
      env = Rack::MockRequest.env_for(url(success: false))

      assert_predicate(subject.new(env), :valid?)
    end

    test "#valid? returns true when code is present in params" do
      env = Rack::MockRequest.env_for(url(success: true))

      assert_predicate(subject.new(env), :valid?)
    end

    test "authentication is not successfull when there is an error" do
      env = Rack::MockRequest.env_for(url(success: false))
      test_obj = subject.new(env)
      test_obj.authenticate!

      assert_not(test_obj.successful?)
      assert_predicate(test_obj, :halted?)
      assert_equal("user canceled the authentication", test_obj.message)
    end

    test "authenication is successfull if a valid token can be fetched" do
      stub_request(:post, TOKEN_ENDPOINT).to_return(code_exchange_response)
      stub_request(:get, JWKS_URL).to_return(jwks_response)
      env = Rack::MockRequest.env_for(url(success: true))
      test_obj = subject.new(env)
      test_obj.authenticate!

      assert_predicate(test_obj, :successful?)
      assert_predicate(test_obj, :halted?)
      assert_equal("john", test_obj.user)
    end

    test "authentication is unsuccessful if the code can not be exchanged for a token" do
      stub_request(:post, TOKEN_ENDPOINT).to_return(status: 400)
      log = StringIO.new
      env = Rack::MockRequest.env_for(url(success: true))
      test_obj = subject.new(env)

      Rails.stub(:logger, Logger.new(log)) do
        test_obj.authenticate!
      end

      assert_not(test_obj.successful?)
      assert_predicate(test_obj, :halted?)
      assert_nil(test_obj.message)

      log.rewind

      assert_match(/Hibiscus could not exchange the recieved code for a token ->/, log.read)
    end

    test "authentication is unsuccessful if the JSON Web Key Set could not be fetched" do
      stub_request(:post, TOKEN_ENDPOINT).to_return(code_exchange_response)
      stub_request(:get, JWKS_URL).to_timeout
      log = StringIO.new
      env = Rack::MockRequest.env_for(url(success: true))
      test_obj = subject.new(env)

      Rails.stub(:logger, Logger.new(log)) do
        test_obj.authenticate!
      end

      assert_not(test_obj.successful?)
      assert_predicate(test_obj, :halted?)
      assert_nil(test_obj.message)

      log.rewind

      assert_match(/Hibiscus could not fetch the providers JSON Web Key Set ->/, log.read)
    end

    test "authentication is unsuccessful if the returned token is invalid" do
      stub_request(:post, TOKEN_ENDPOINT).to_return(code_exchange_response("invalid.token"))
      stub_request(:get, JWKS_URL).to_return(jwks_response)
      log = StringIO.new
      env = Rack::MockRequest.env_for(url(success: true))
      test_obj = subject.new(env)

      Rails.stub(:logger, Logger.new(log)) do
        test_obj.authenticate!
      end

      assert_not(test_obj.successful?)
      assert_predicate(test_obj, :halted?)
      assert_nil(test_obj.message)

      log.rewind

      assert_match(/Hibiscus encountered an error while decoding the recieved token ->/, log.read)
    end

    test "authentication is unsuccessful if the supplied user_finder proc returns nil" do
      stub_request(:post, TOKEN_ENDPOINT).to_return(code_exchange_response(token("jane")))
      stub_request(:get, JWKS_URL).to_return(jwks_response)
      log = StringIO.new
      env = Rack::MockRequest.env_for(url(success: true))
      test_obj = subject.new(env)

      Rails.stub(:logger, Logger.new(log)) do
        test_obj.authenticate!
      end

      assert_not(test_obj.successful?)
      assert_predicate(test_obj, :halted?)
      assert_nil(test_obj.message)

      log.rewind

      assert_predicate(log.read, :blank?)
    end

    private

    def subject
      @subject ||= begin
        stub_request(:get, METADATA_URL).to_return(metadata_response)

        Class.new(Hibiscus::Strategy) do
          @provider_config = ProviderConfig.new(client_id: "id", client_secret: "secret", metadata_url: METADATA_URL,
                                                user_finder: ->(claims) { "john" if ["john"].include?(claims[:name]) })

          class << self
            attr_reader :provider_config
          end
        end
      end
    end

    def url(success: true)
      return "http://localhost?error=access_denied&error_description=user+canceled+the+authentication" unless success

      "http://localhost?code=AwABAAAAvPM1KaPlrEqdFSBzjqfTGBCmLdgfSTLEMPGYuNHSUYBrq&state=12345"
    end

    def metadata_response
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { token_endpoint: TOKEN_ENDPOINT, issuer: "hibiscus-test", jwks_uri: JWKS_URL }.to_json
      }
    end

    def code_exchange_response(id_token = token)
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { id_token: id_token }.to_json
      }
    end

    def jwks_response
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { keys: [jwk.export] }.to_json
      }
    end

    def token(name = "john")
      time = Time.now.to_i
      headers = { kid: jwk.kid, typ: "JWT" }
      payload = { exp: (time + 300),
                  nbf: (time - 300),
                  iat: (time - 300),
                  iss: "hibiscus-test",
                  aud: "id",
                  name: name }

      JWT.encode(payload, jwk.keypair, "RS256", headers)
    end

    def jwk
      @jwk ||= JWT::JWK.new(OpenSSL::PKey::RSA.new(2048))
    end
  end
end
