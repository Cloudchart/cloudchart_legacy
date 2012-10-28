Cloudchart::Application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "omniauth", registrations: "registrations", sessions: "sessions" } do
    get "/users/profile" => "registrations#profile", as: :user_profile
  end
  root to: "landing#index"
  
  # Admin
  god = lambda { |request| Rails.env.development? || (request.env["warden"].authenticate? and request.env["warden"].user.god?) }
  constraints god do
    mount RailsAdmin::Engine => "/admin", as: "rails_admin"
  end
end
