# frozen_string_literal: true

Rails.application.routes.draw do
  # Built-in Rails health check (used by load balancers / Kamal).
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # ---------------------------------------------------------------
      # Health
      # ---------------------------------------------------------------
      get "health", to: "health#show"

      # ---------------------------------------------------------------
      # Authentication
      # ---------------------------------------------------------------
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"
      post "auth/forgot_password", to: "auth#forgot_password"
      post "auth/reset_password", to: "auth#reset_password"

      # ---------------------------------------------------------------
      # Profile
      # ---------------------------------------------------------------
      get "profile", to: "users#show"
      patch "profile", to: "users#update"
      post "profile/avatar", to: "users#upload_avatar"

      # ---------------------------------------------------------------
      # Dashboard
      # ---------------------------------------------------------------
      get "dashboard", to: "dashboard#show"

      # ---------------------------------------------------------------
      # Notifications
      # ---------------------------------------------------------------
      resources :notifications, only: [ :index, :update ] do
        collection do
          post :mark_all_read
        end
      end

      # ---------------------------------------------------------------
      # Workspaces + nested memberships / projects
      # ---------------------------------------------------------------
      resources :workspaces do
        member do
          post :invite
        end

        resources :memberships, only: [ :index, :update, :destroy ]
        resources :projects, only: [ :index, :create ]
      end

      # Shallow routes — shorter URLs for nested resources
      resources :projects, only: [ :show, :update, :destroy ] do
        member do
          post :archive
          post :restore
        end

        resources :tasks, only: [ :index, :create ]
      end

      resources :tasks, only: [ :show, :update, :destroy ] do
        resources :comments, only: [ :index, :create ]
        resources :attachments, only: [ :index, :create ]
      end

      resources :comments, only: [ :show, :update, :destroy ]

      resources :attachments, only: [ :destroy ] do
        member do
          get :download
        end
      end
    end
  end
end
