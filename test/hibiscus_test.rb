# frozen_string_literal: true

require "test_helper"

class HibiscusTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert Hibiscus::VERSION
  end

  test "::register_provider registers a warden strategey" do
    stub_request(:get, "http://t.int/").to_return(metadata_response)

    assert_changes(-> { Warden::Strategies[:test] }, from: nil, to: Class) do
      Hibiscus.register_provider(:test, client_id: "id", client_secret: "secret", metadata_url: "http://t.int") { nil }
    end

    assert_includes(Warden::Strategies[:test].ancestors, Hibiscus::Strategy)
  end

  private

  def metadata_response
    {
      status: 200,
      headers: { "Content-Type" => "application/json" },
      body: "{}"
    }
  end
end
