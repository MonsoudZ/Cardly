Rails.application.routes.draw do
  devise_for :users

  # Profile routes
  resource :profile, only: [ :show, :edit, :update ]

  # Collection routes
  resources :collections do
    resources :collection_items, only: [ :new, :create, :edit, :update, :destroy ]
  end

  # Marketplace - browse items for sale/trade
  get "marketplace", to: "marketplace#index"

  # Cards catalog
  resources :cards, only: [ :index, :show ]

  root "home#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
end
