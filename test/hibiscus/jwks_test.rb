# frozen_string_literal: true

require "test_helper"

module Hibiscus
  class JWKSTest < ActiveSupport::TestCase
    TEST_URL = "https://test.int/jwks"
    private_constant :TEST_URL

    KEY_SET = { keys: [JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)).export] }.freeze
    private_constant :KEY_SET

    setup do
      @cache = ActiveSupport::Cache::MemoryStore.new
    end

    test "when data is not cached it fetches the jwks from the internet" do
      webmock_stub = stub_request(:get, TEST_URL).to_return(response)
      subject.to_h

      assert_requested(webmock_stub)
    end

    test "it caches the result" do
      stub_request(:get, TEST_URL).to_return(response)
      test_subject = subject

      assert_changes(-> { @cache.read(test_subject.cache_key) }, from: nil, to: KEY_SET) do
        test_subject.to_h
      end
    end

    test "it raises an error if the document can not be fetched" do
      stub_request(:get, TEST_URL).to_timeout

      assert_raises(JWKSFetchError) do
        subject.to_h
      end
    end

    test "#to_h returns a hash representation of the jwks" do
      stub_request(:get, TEST_URL).to_return(response)

      assert_equal(KEY_SET, subject.to_h)
    end

    test "when data is cached it does not fetch the jwks" do
      webmock_stub = stub_request(:get, TEST_URL).to_return(response)
      test_subject = subject
      @cache.write(test_subject.cache_key, JWKS)
      result = subject.to_h

      assert_equal(JWKS, result)
      assert_not_requested(webmock_stub)
    end

    private

    def subject
      JWKS.new(TEST_URL, @cache)
    end

    def response
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: KEY_SET.to_json
      }
    end
  end
end
