Rails.application.routes.draw do

  root "pages#home"

  get "/login", to: 'sessions#new'
  post "/login", to: 'sessions#create'
  delete "/logout", to: 'sessions#destroy'

  resources :tickets, only: [:index, :show, :new, :create] do
    resources :comments, only: [:create]
    patch :assign, on: :member
    patch :update_status, on: :member
    patch :update_priority, on: :member
  end
end
