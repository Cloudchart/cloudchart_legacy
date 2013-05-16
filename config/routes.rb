Cloudchart::Application.routes.draw do
  # App
  resources :organizations do
    resources :nodes, only: [:index, :show, :update]
    resources :persons do
      collection do
        get :search
      end
      member do
        get :manage
      end
    end
  end
  
  resources :persons, only: [:edit]
  
  # Users
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth",
    registrations: "registrations",
    sessions: "sessions",
    invitations: "invitations"
  }
  
  # devise_scope :user do
  #   post "/users/invite" => "registrations#invite", as: :user_invite
  # end
  
  # God
  require "sidekiq/web"
  god = lambda { |request| Rails.env.development? || (request.env["warden"].authenticate? and request.env["warden"].user.god?) }
  constraints god do
    mount Sidekiq::Web => "/sidekiq"
  end
  
  root to: "welcome#index"
end
