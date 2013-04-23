Cloudchart::Application.routes.draw do
  # App
  resources :nodes, only: [:index, :show, :update]
  resources :persons, only: [:index, :create, :show] do
    collection do
      get :search
    end
  end
  
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
  
  root to: "application#home"
end
