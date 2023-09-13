# frozen_string_literal: true

require "test_helper"

module Hibiscus
  class ConfigTest < ActiveSupport::TestCase
    TEST_URL = "https://test.int/metadata"
    private_constant :TEST_URL

    RESPONSE_BODY = { token_endpoint: "https://test.int/token" }.freeze
    private_constant :RESPONSE_BODY

    test "the metadata document is fetched from the internet" do
      # webmock_stub = stub_request(:get, TEST_URL).to_return(response)
      metadata = subject.metadata

      assert_requested(webmock_stub)
      assert_equal(RESPONSE_BODY, metadata)
    end

    # test "it caches the result" do
    #   stub_request(:get, TEST_URL).to_return(response)

    #   assert_changes(-> { @cache.read(cache_key) }, from: nil, to: RESPONSE_BODY) do
    #     subject
    #   end
    # end

    # test "it raises an error if the document can not be fetched" do
    #   stub_request(:get, TEST_URL).to_timeout

    #   assert_raises(MetadataFetchError) do
    #     subject.to_h
    #   end
    # end

    # test "method_missing fetches the attribute if it exists in the metadata" do
    #   stub_request(:get, TEST_URL).to_return(response)

    #   assert_equal("https://test.int/token", subject.token_endpoint)
    # end

    # test "method missing raise an error if the attributes does not exist in the document" do
    #   stub_request(:get, TEST_URL).to_return(response)

    #   assert_raises(NoMethodError) do
    #     subject.non_existant_attrinbute
    #   end
    # end

    # test "when data is cached it does not fetch the document" do
    #   webmock_stub = stub_request(:get, TEST_URL).to_return(response)
    #   @cache.write(cache_key, RESPONSE_BODY)
    #   result = subject.to_h

    #   assert_equal(RESPONSE_BODY, result)
    #   assert_not_requested(webmock_stub)
    # end

    private

    def subject
      Hibiscus::Config.new(client_id: "id", client_secret: "secret", metadata_url: TEST_URL, user_finder: -> {})
    end

    def response
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: RESPONSE_BODY.to_json
      }
    end
  end
end
