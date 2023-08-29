# frozen_string_literal: true

module Hibiscus
  class SessionsController < ApplicationController
    before_action :redirect_authenticated_users, except: [:destroy]

    def new
      raise
    end

    private

    EMPTY_OPTIONS = {}.freeze
    private_constant :EMPTY_OPTIONS

    def redirect_authenticated_users
      return unless warden.authenticated?(scope)

      redirect_to(redirect_path, notice: t("hibiscus.already_logged_in"))
    end

    def authorization_url(state_string)
      uri = URI(metadata['authorization_endpoint'])
    end

    def metadata
      Hibiscus::Metadata.new()
    end

    def scope
      options.fetch("scope") { warden.config.default_scope }
             .to_sym
    end

    def redirect_path
      options.fetch("redirect_to")
    end

    def options
      flash[:hibiscus] || EMPTY_OPTIONS
    end

    def warden
      request.env["warden"]
    end
  end
end
