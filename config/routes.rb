Rails.application.routes.draw do
  namespace :hibiscus do
    resource :session, only: [:show, :new, :destroy]
  end
end
