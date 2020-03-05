# frozen_string_literal: true

# Generate the application's routes
Rails.application.routes.draw do
  # Generate necessary routes for devise
  devise_for :users

  # Generate api/v1 routes
  namespace :api do
    namespace :v1 do
      # User's images, categories, and win total routes
      resources :images
      resources :categories
      resources :win_total, path: '/win-total', only: %i[index update]

      # Authentication routes
      resource :sessions, only: %i[create update destroy]
      resource :users, only: %i[create destroy]
    end
  end
end
