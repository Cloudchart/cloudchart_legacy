Cloudchart::Application.routes.draw do
  # App
  resources :charts do
    resources :versions, except: [:new, :create]
    member do
      get "token/:token", action: "token", via: [:get], as: :token
    end
  end
  
  # Users
  devise_for :users, controllers: { omniauth_callbacks: "omniauth", registrations: "registrations", sessions: "sessions" } do
    get "/users/profile" => "registrations#profile", as: :user_profile
  end
  
  # Root
  root to: "landing#index"
  
  # Admin
  god = lambda { |request| Rails.env.development? || (request.env["warden"].authenticate? and request.env["warden"].user.god?) }
  constraints god do
    mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  end
end
