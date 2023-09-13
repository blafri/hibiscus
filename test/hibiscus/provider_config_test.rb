# frozen_string_literal: true

require "test_helper"

module Hibiscus
  class ProviderConfigTest < ActiveSupport::TestCase
    TEST_URL = "https://test.int/metadata"
    private_constant :TEST_URL

    RESPONSE_BODY = { token_endpoint: "https://test.int/token" }.freeze
    private_constant :RESPONSE_BODY

    test "the metadata document is fetched from the internet" do
      webmock_stub = stub_request(:get, TEST_URL).to_return(response)

      assert_equal(RESPONSE_BODY, subject.metadata)
      assert_requested(webmock_stub)
    end

    test "it raises an error if the document can not be fetched" do
      stub_request(:get, TEST_URL).to_timeout

      assert_raises(MetadataFetchError) do
        subject
      end
    end

    test "metadata can be fetched from the config" do
      stub_request(:get, TEST_URL).to_return(response)

      assert_equal("https://test.int/token", subject.token_endpoint)
    end

    test "an error is raised when the metadata attribute does not exist in the config" do
      stub_request(:get, TEST_URL).to_return(response)

      assert_raises(NoMethodError) do
        subject.non_existant_attrinbute
      end
    end

    private

    def subject
      ProviderConfig.new(client_id: "id", client_secret: "secret", metadata_url: TEST_URL, user_finder: -> {})
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
