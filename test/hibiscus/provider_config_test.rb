# frozen_string_literal: true

require "test_helper"

module Hibiscus
  class ProviderConfigTest < ActiveSupport::TestCase
    TEST_URL = "https://test.int/metadata"
    private_constant :TEST_URL

    test "metadata document is fetched from the internet and not cached if there is no cache-control header" do
      webmock_stub = stub_request(:get, TEST_URL).to_return(metadata_response)

      assert_equal(METADATA_RESPONSE_BODY[:token_endpoint], subject.token_endpoint)
      assert_equal(METADATA_RESPONSE_BODY[:token_endpoint], subject.token_endpoint)
      assert_requested(webmock_stub, times: 2)
    end

    test "metadata document is fetched from the internet and cached if there is a cache-control header" do
      webmock_stub = stub_request(:get, TEST_URL).to_return(metadata_response(3600))

      assert_equal(METADATA_RESPONSE_BODY[:token_endpoint], subject.token_endpoint)
      assert_equal(METADATA_RESPONSE_BODY[:token_endpoint], subject.token_endpoint)
      assert_requested(webmock_stub, times: 1)
    end

    test "metadata document is refetched from the internet when the cache gets stale" do
      webmock_stub = stub_request(:get, TEST_URL).to_return(metadata_response(3600))
      current_time = Time.now

      Time.stub(:now, current_time) do
        assert_equal(METADATA_RESPONSE_BODY[:token_endpoint], subject.token_endpoint)
      end

      Time.stub(:now, Time.at(current_time.to_i + 3600)) do
        assert_equal(METADATA_RESPONSE_BODY[:token_endpoint], subject.token_endpoint)
      end

      assert_requested(webmock_stub, times: 2)
    end

    test "it raises an error if the metadata document can not be fetched" do
      stub_request(:get, TEST_URL).to_timeout

      assert_raises(MetadataFetchError) do
        subject.token_endpoint
      end
    end

    test "jwks is fetched from the internet and not cached if there is no cache-control header" do
      stub_request(:get, TEST_URL).to_return(metadata_response(3600))
      webmock_stub = stub_request(:get, "https://test.int/jwks").to_return(jwks_response)

      assert_equal(JWKS_RESPONSE_BODY, subject.jwks)
      assert_equal(JWKS_RESPONSE_BODY, subject.jwks)
      assert_requested(webmock_stub, times: 2)
    end

    test "jwks is fetched from the internet and cached if there is a cache-control header" do
      stub_request(:get, TEST_URL).to_return(metadata_response(3600))
      webmock_stub = stub_request(:get, "https://test.int/jwks").to_return(jwks_response(3600))

      assert_equal(JWKS_RESPONSE_BODY, subject.jwks)
      assert_equal(JWKS_RESPONSE_BODY, subject.jwks)
      assert_requested(webmock_stub, times: 1)
    end

    test "jwks is refetched from the internet when the cache gets stale" do
      stub_request(:get, TEST_URL).to_return(metadata_response(3600))
      webmock_stub = stub_request(:get, "https://test.int/jwks").to_return(jwks_response(3600))
      current_time = Time.now

      Time.stub(:now, current_time) do
        assert_equal(JWKS_RESPONSE_BODY, subject.jwks)
      end

      Time.stub(:now, Time.at(current_time.to_i + 3600)) do
        assert_equal(JWKS_RESPONSE_BODY, subject.jwks)
      end

      assert_requested(webmock_stub, times: 2)
    end

    test "it raises an error if the jwks can not be fetched" do
      stub_request(:get, TEST_URL).to_return(metadata_response(3600))
      stub_request(:get, "https://test.int/jwks").to_timeout

      assert_raises(Hibiscus::JWKSFetchError) do
        subject.jwks
      end
    end

    private

    def subject
      @subject ||= ProviderConfig.new(client_id: "id", client_secret: "secret", metadata_url: TEST_URL,
                                      user_finder: -> {})
    end

    METADATA_RESPONSE_BODY = { token_endpoint: "https://test.int/token", jwks_uri: "https://test.int/jwks" }.freeze
    private_constant :METADATA_RESPONSE_BODY

    def metadata_response(max_age = nil)
      headers = { "Content-Type" => "application/json" }
      headers.merge!({ "Cache-Control" => "max-age=#{max_age}, private" }) unless max_age.nil?

      {
        status: 200,
        headers: headers,
        body: METADATA_RESPONSE_BODY.to_json
      }
    end

    JWKS_RESPONSE_BODY = { keys: {} }.freeze
    private_constant :JWKS_RESPONSE_BODY

    def jwks_response(max_age = nil)
      headers = { "Content-Type" => "application/json" }
      headers.merge!({ "Cache-Control" => "max-age=#{max_age}, private" }) unless max_age.nil?

      {
        status: 200,
        headers: headers,
        body: JWKS_RESPONSE_BODY.to_json
      }
    end
  end
end
