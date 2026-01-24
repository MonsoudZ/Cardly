Rails.application.routes.draw do
  devise_for :users

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    resources :users do
      member do
        post :toggle_admin
      end
    end
    resources :listings, only: [ :index, :show ] do
      member do
        post :cancel
      end
    end
    resources :transactions, only: [ :index, :show ]
    resources :disputes, only: [ :index, :show ] do
      member do
        post :review
        post :resolve
        post :close
        post :reopen
        post :add_message
      end
    end
  end

  # Profile routes (current user's own profile)
  resource :profile, only: [ :show, :edit, :update ]

  # Public user profiles
  resources :users, only: [ :show ], path: "u"

  # Wallet - user's gift cards
  resource :wallet, only: [ :show ]

  # Card categories/tags
  resources :tags, except: [ :show ] do
    collection do
      post :create_suggestions
    end
  end

  # Gift cards management
  resources :gift_cards do
    member do
      post :list_for_sale
      post :list_for_trade
    end
    # Spending tracker
    resources :card_activities, except: [ :show ] do
      collection do
        post :quick_purchase
      end
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
      post :counter
      post :accept_counter
      post :reject_counter
    end
    # Ratings for completed transactions
    resource :rating, only: [ :new, :create ]
    # Messages between buyer and seller
    resources :messages, only: [ :create ]
    # Payments
    resource :payment, only: [] do
      post :checkout
      get :success
      get :cancel
    end
    # Disputes
    resources :disputes, only: [ :new, :create ]
  end

  # User disputes
  resources :disputes, only: [ :index, :show ] do
    member do
      post :add_message
    end
  end

  # Stripe Connect for sellers
  get "connect/onboard", to: "stripe_connect#onboard", as: :stripe_connect_onboard
  get "connect/return", to: "stripe_connect#return", as: :stripe_connect_return
  get "connect/refresh", to: "stripe_connect#refresh", as: :stripe_connect_refresh

  # Webhooks (no auth required)
  post "webhooks/stripe", to: "webhooks#stripe"

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
