Rails.application.routes.draw do
  devise_for :users

  # Profile routes (current user's own profile)
  resource :profile, only: [ :show, :edit, :update ]

  # Public user profiles
  resources :users, only: [ :show ], path: "u"

  # Wallet - user's gift cards
  resource :wallet, only: [ :show ]

  # Gift cards management
  resources :gift_cards do
    member do
      post :list_for_sale
      post :list_for_trade
    end
  end

  # Listings management
  resources :listings, only: [ :show, :create, :edit, :update, :destroy ] do
    member do
      post :cancel
    end
    # Transaction offers on a listing
    resources :transactions, only: [ :new, :create ]
    # Favorites
    resource :favorite, only: [ :create, :destroy ]
  end

  # Watchlist
  resources :favorites, only: [ :index ]

  # Transaction management
  resources :transactions, only: [ :index, :show ] do
    member do
      post :accept
      post :reject
      post :cancel
    end
    # Ratings for completed transactions
    resource :rating, only: [ :new, :create ]
    # Messages between buyer and seller
    resources :messages, only: [ :create ]
  end

  # Marketplace - browse listings
  get "marketplace", to: "marketplace#index"
  get "marketplace/sales", to: "marketplace#sales", as: :marketplace_sales
  get "marketplace/trades", to: "marketplace#trades", as: :marketplace_trades

  # Brands catalog
  resources :brands, only: [ :index, :show ]

  root "home#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
