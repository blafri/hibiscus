# frozen_string_literal: true

class DashboardsController < ApplicationController
  def show
    if request.env["warden"].authenticated?(:user)
      render(plain: "OK")
      return
    end

    flash[:hibiscus] = { provider: :openid_test, scope: :user, redirect_to: dashboard_path }
    redirect_to(new_hibiscus_session_path)
  end
end
