# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require "webmock/minitest"

###############################################################################
# We need to put this here because when the dummy rails app loads it will try to get the metadata from the internet
# becuase we are registering a hibiscus openid provider in config/initializers/hibiscus.rb.
body = {
  authorization_endpoint: "https://hibiscus-openid-test.int/authorize",
  token_endpoint: "https://hibiscus-openid-test.int/token",
  jwks_uri: "https://hibiscus-openid-test.int/keys",
  issuer: "hibiscus-openid-tester"
}

WebMock.stub_request(:get, "https://hibiscus-openid-test.int/metadata")
  .to_return(status: 200, headers: { "Content-Type" => "application/json" },body: body.to_json)
###############################################################################

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
require "rails/test_help"
require "minitest/mock"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end
