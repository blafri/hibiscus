# frozen_string_literal: true

require "erb"
require "securerandom"

module Hibiscus
  # @api private
  module ControllerActions
    extend ActiveSupport::Concern
    include ERB::Util

    included do
      before_action :redirect_authenticated_users, except: [:destroy]
    end

    def show
      state = flash[:hibiscus].fetch("state")
      redirect_path = flash[:hibiscus].fetch("redirect_path")
      raise Hibiscus::InvalidStateError unless state.present? && state == params[:state]

      request.env["warden"].authenticate!(provider, scope: warden_scope)
      redirect_to(redirect_path)
    end

    def new
      state = SecureRandom.alphanumeric
      auth_url = authorization_url(state)
      redirect_path = params.require(:redirect_path)

      flash[:hibiscus] = { redirect_path: redirect_path, state: state }
      redirect_to(auth_url, allow_other_host: true)
    end

    private

    def redirect_authenticated_users
      return unless warden.authenticated?(warden_scope)

      path = params.require(:redirect_path)
      redirect_to(path)
    end

    def authorization_url(state)
      provider_config = Warden::Strategies[provider].provider_config

      query = [
        "client_id=#{url_encode(provider_config.client_id)}",
        "redirect_uri=#{url_encode(authorization_callback_url)}",
        "scope=#{url_encode('openid profile email')}",
        "state=#{url_encode(state)}",
        "response_mode=query",
        "response_type=code"
      ]

      "#{provider_config.authorization_endpoint}?#{query.join("&")}"
    end

    def authorization_callback_url
      (request.base_url + request.path).delete_suffix("/new")
    end

    def provider
      raise StandardError, "You must implement this method"
    end

    def warden_scope
      raise StandardError, "You must implement this method"
    end
  end
end
