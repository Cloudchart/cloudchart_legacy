Cloudchart::Application.routes.draw do
  # App
  resources :charts do
    member do
      get  "token/:token", action: "token", via: [:get], as: :token
      post :clone
    end
    resources :versions, except: [:new, :create, :destroy] do
      put :restore
      post :clone
    end
    resources :nodes, except: [:index, :new, :create, :destroy]
    resources :persons, only: [:index]
  end
  
  resources :pages, only: [:show]
  
  # Users
  devise_for :users, controllers: { omniauth_callbacks: "omniauth", registrations: "registrations", sessions: "sessions" } do
    get "/users/profile" => "registrations#profile", as: :user_profile
  end
  
  # Root
  match '/beta', to: "landing#beta"
  root to: "landing#index"
  
  # Admin
  god = lambda { |request| Rails.env.development? || (request.env["warden"].authenticate? and request.env["warden"].user.god?) }
  constraints god do
    mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  end
end
