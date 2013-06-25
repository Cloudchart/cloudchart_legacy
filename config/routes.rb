Cloudchart::Application.routes.draw do
  # App
  resources :organizations do
    member do
      get :widgets
      get :"page/:page", action: :page, as: :page
    end
    
    resources :charts, only: [:index, :new, :create, :show]
    resources :nodes, only: [:index, :show, :update]
    resources :identities, except: [:edit] do
      member do
        get :manage
        put :invite
      end
    end
    resources :vacancies, only: [:new, :create]
  end
  
  resources :persons, only: [:edit, :update] do
    collection do
      get :search
    end
  end
  
  # Users
  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth",
    sessions: "sessions",
    registrations: "registrations",
    confirmations: "confirmations",
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
