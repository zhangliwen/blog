Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'homes#index'

  resources :sessions, only: [:new, :create, :destroy] do
    collection do
      post :login
      get :sign_in
    end
  end

  resources :articles, only: [:show, :new, :create]
  resources :comments
end
