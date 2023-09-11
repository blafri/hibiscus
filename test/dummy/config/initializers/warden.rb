# frozen_string_literal: true

Rails.application.config.middleware.use Warden::Manager do |config|
  config.failure_app = ->(_env) do
    Rails.logger.info("Warden failure application invoked")
    [401, { "Content-Type" => "text/plain" }, ["Unauthorized"]]
  end

  # set default scope
  config.default_scope = :user

  # Tell warden how to serialize and deserialize session information for each scope
  config.serialize_into_session(:user, &:to_s)
  config.serialize_from_session(:user, &:to_s)
end
