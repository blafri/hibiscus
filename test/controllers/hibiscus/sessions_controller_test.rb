# frozen_string_literal: true

require "test_helper"

module Hibiscus
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    include Warden::Test::Helpers
    include ERB::Util

    teardown { Warden.test_reset! }

    # class Show < SessionsControllerTest
    #   test "should redirect to dashboard page if authenticated" do
    #     stub_request(:get, "https://openid-test.int/metadata").to_return(openid_metadata_stub_response)
    #     get(dashboard_path)

    #     assert_redirected_to(new_hibiscus_session_path)
    #     follow_redirect!
    #     login_as("user", scope: :user)
    #     get(hibiscus_session_path)

    #     assert_redirected_to(dashboard_path)
    #     assert_equal("You are already logged in", flash[:notice])
    #   end

    #   test "throws error when state is not present" do
    #     assert_raises(Hibiscus::InvalidStateError) do
    #       get(hibiscus_session_path)
    #     end
    #   end

    #   test "throws error when state does not match" do
    #     stub_request(:get, "https://openid-test.int/metadata").to_return(openid_metadata_stub_response)

    #     SecureRandom.stub(:alphanumeric, "randomState") do
    #       get(dashboard_path)

    #       assert_redirected_to(new_hibiscus_session_path)
    #       follow_redirect!
    #     end

    #     assert_raises(Hibiscus::InvalidStateError) do
    #       get(hibiscus_session_path(state: "incorrectState"))
    #     end
    #   end

    #   test "logs the user in when authentication is successfull" do
    #     stub_request(:get, "https://openid-test.int/metadata").to_return(openid_metadata_stub_response)
    #     stub_request(:post, "https://openid-test.int/token").to_return(token_endpoint_stub_response)
    #     stub_request(:get, "https://openid-test.int/keys").to_return(jwks_endpoint_stub_response)

    #     SecureRandom.stub(:alphanumeric, "randomState") do
    #       get(dashboard_path)

    #       assert_redirected_to(new_hibiscus_session_path)
    #       follow_redirect!
    #     end

    #     assert_changes(-> { request.env["warden"].user }, from: nil, to: "john") do
    #       get(hibiscus_session_path(code: "test_code", state: "randomState"))
    #     end
    #   end

    #   test "redirects the user to the url in the flash when authentication is successfull" do
    #     stub_request(:get, "https://openid-test.int/metadata").to_return(openid_metadata_stub_response)
    #     stub_request(:post, "https://openid-test.int/token").to_return(token_endpoint_stub_response)
    #     stub_request(:get, "https://openid-test.int/keys").to_return(jwks_endpoint_stub_response)

    #     SecureRandom.stub(:alphanumeric, "randomState") do
    #       get(dashboard_path)

    #       assert_redirected_to(new_hibiscus_session_path)
    #       follow_redirect!
    #     end

    #     get(hibiscus_session_path(code: "test_code", state: "randomState"))

    #     assert_redirected_to(dashboard_path)
    #     follow_redirect!

    #     assert_response(:ok)
    #   end

    #   test "provider used is stored in warden session after successfull authentication" do
    #     stub_request(:get, "https://openid-test.int/metadata").to_return(openid_metadata_stub_response)
    #     stub_request(:post, "https://openid-test.int/token").to_return(token_endpoint_stub_response)
    #     stub_request(:get, "https://openid-test.int/keys").to_return(jwks_endpoint_stub_response)

    #     SecureRandom.stub(:alphanumeric, "randomState") do
    #       get(dashboard_path)

    #       assert_redirected_to(new_hibiscus_session_path)
    #       follow_redirect!
    #     end

    #     get(hibiscus_session_path(code: "test_code", state: "randomState"))
    #     assert_equal(:openid_test, request.env["warden"].session(:user)["provider"])
    #   end

    #   test "runs the warden failure app when the authentication fails" do
    #     stub_request(:get, "https://openid-test.int/metadata").to_return(openid_metadata_stub_response)

    #     SecureRandom.stub(:alphanumeric, "randomState") do
    #       get(dashboard_path)

    #       assert_redirected_to(new_hibiscus_session_path)
    #       follow_redirect!
    #     end

    #     get(hibiscus_session_path(error: "invalid", state: "randomState"))

    #     assert_response(:unauthorized)
    #     assert_equal("Unauthorized", response.body)
    #   end
    # end

    # class New < SessionsControllerTest
    #   test "should redirect to dashboard page if authenticated" do
    #     get(dashboard_path)

    #     assert_redirected_to(new_hibiscus_session_path)

    #     login_as("user", scope: :user)
    #     follow_redirect!

    #     assert_redirected_to(dashboard_path)
    #     assert_equal("You are already logged in", flash[:notice])
    #   end

    #   test "should redirect to OpenID authorize endpoint" do
    #     stub_request(:get, "https://openid-test.int/metadata").to_return(openid_metadata_stub_response)
    #     options = { provider: :openid_test, scope: :user, redirect_to: "/dashboard", state: "randomState" }
    #     url = "https://openid-test.int/authorize?" \
    #           "client_id=test-id&" \
    #           "redirect_uri=#{url_encode(hibiscus_session_url)}&" \
    #           "scope=openid%20profile%20email&" \
    #           "state=randomState&" \
    #           "response_mode=query&" \
    #           "response_type=code"

    #     SecureRandom.stub(:alphanumeric, "randomState") do
    #       get(dashboard_path)

    #       assert_redirected_to(new_hibiscus_session_path)
    #       follow_redirect!
    #     end

    #     assert_redirected_to(url)
    #     assert_equal(options, flash[:hibiscus])
    #   end
    # end

    private

    def token_endpoint_stub_response
      time = Time.now.to_i
      headers = { kid: jwk.kid, typ: "JWT" }
      payload = { exp: (time + 300), nbf: (time - 300), iat: (time - 300), iss: "tester", aud: "test-id", name: "john" }

      stubbed_response_hash({
        id_token: JWT.encode(payload, jwk.keypair, "RS256", headers)
      })
    end

    def jwks_endpoint_stub_response
      stubbed_response_hash({
        keys: [jwk.export]
      })
    end

    def jwk
      @jwk ||= JWT::JWK.new(OpenSSL::PKey::RSA.new(2048))
    end

    def stubbed_response_hash(body)
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: body.to_json
      }
    end
  end
end
