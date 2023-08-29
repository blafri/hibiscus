# frozen_string_literal: true

require "test_helper"

module Hibiscus
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    include Warden::Test::Helpers
    include ERB::Util

    teardown { Warden.test_reset! }

    class New < SessionsControllerTest
      test "should redirect to dashboard page if authenticated" do
        get(dashboard_path)

        assert_redirected_to(new_hibiscus_session_path)

        login_as("user", scope: :user)
        follow_redirect!

        assert_redirected_to(dashboard_path)
        assert_equal("You are already logged in", flash[:notice])
      end

      # test "should redirect to OpenID authorize endpoint" do
      #   # stub_request(:get, openid_metadata_url).to_return(openid_metadata_stub_response)

      #   url = "http://openid-test.int/authorize?client_id=test_id&" \
      #         "redirect_uri=#{url_encode(hibiscus_session_path)}&" \
      #         "scope=openid%20profile%20email&" \
      #         "state=randomState&" \
      #         "response_mode=query&" \
      #         "response_type=code"

      #   SecureRandom.stub(:alphanumeric, "randomState") do
      #     get(dashboard_path)
      #     assert_redirected_to(new_hibiscus_session_path)
      #     follow_redirect!
      #   end

      #   assert_redirected_to(url)
      # end
    end
  end
end
