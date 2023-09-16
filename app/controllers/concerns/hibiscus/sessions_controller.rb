# frozen_string_literal: true

require "erb"
require "securerandom"

module Hibiscus
  class SessionsController < ApplicationController
    include ERB::Util

    before_action :redirect_authenticated_users, except: [:destroy]

    def show
      state = hibiscus_options["state"]
      raise Hibiscus::InvalidStateError unless state.present? && state == params[:state]

      provider = hibiscus_provider
      scope = warden_scope

      warden.authenticate!(provider, scope: scope)

      warden.session(scope)["provider"] = provider
      redirect_to(redirect_path)
    end

    def new
      state = SecureRandom.alphanumeric
      redirect_url = authorization_url(state)

      flash[:hibiscus] = { provider: hibiscus_provider, scope: warden_scope, redirect_to: redirect_path, state: state }
      redirect_to(redirect_url, allow_other_host: true)
    end

    private

    EMPTY_OPTIONS = {}.freeze
    private_constant :EMPTY_OPTIONS

    def redirect_authenticated_users
      return unless warden.authenticated?(warden_scope)

      redirect_to(redirect_path, notice: t("hibiscus.already_logged_in"))
    end

    def authorization_url(state)
      endpoint = Hibiscus::Metadata.new(metadata_url).authorization_endpoint
      query = [
        "client_id=#{url_encode(client_id)}",
        "redirect_uri=#{url_encode(hibiscus_session_url)}",
        "scope=#{url_encode('openid profile email')}",
        "state=#{url_encode(state)}",
        "response_mode=query",
        "response_type=code"
      ]

      "#{endpoint}?#{query.join("&")}"
    end

    def warden_scope
      hibiscus_options.fetch("scope") { warden.config.default_scope }
                      .to_sym
    end

    def redirect_path
      hibiscus_options.fetch("redirect_to")
    end

    def hibiscus_provider
      hibiscus_options.fetch("provider").to_sym
    end

    def hibiscus_options
      flash[:hibiscus] || EMPTY_OPTIONS
    end

    def client_id
      provider_config.client_id
    end

    def metadata_url
      provider_config.metadata_url
    end

    def provider_config
      Warden::Strategies[hibiscus_provider].provider_config
    end

    def warden
      request.env["warden"]
    end
  end
end
