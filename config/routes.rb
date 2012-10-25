Cloudchart::Application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "omniauth", registrations: "registrations" } do
    get "/users/profile" => "registrations#profile", as: :user_profile
  end
  root to: "landing#index"
end
