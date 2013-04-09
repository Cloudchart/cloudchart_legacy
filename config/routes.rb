Cloudchart::Application.routes.draw do
  resources :nodes, only: [:index, :show, :update]
end
