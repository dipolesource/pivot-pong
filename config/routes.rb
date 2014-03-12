PivotPong::Application.routes.draw do
  resources :matches, only: [:create, :index]
  resources :players, only: :show, param: :key

  root 'dashboard#show'
end