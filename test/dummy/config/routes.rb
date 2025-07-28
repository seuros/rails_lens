# frozen_string_literal: true

Rails.application.routes.draw do
  # Health check
  get 'health', to: 'health#show'

  # Test endpoints
  get 'test', to: 'test#index'

  # Spaceship management
  resources :spaceships do
    member do
      patch :assign_crew
      delete :decommission
    end

    collection do
      get :active
      get :maintenance
    end
  end

  # Crew management
  resources :crew_members do
    member do
      patch :assign_to_ship
      patch :promote
      patch :update_status
    end

    collection do
      get :active
      get :by_specialization
      get :by_rank
    end
  end

  # Alias routes for crew members (demonstrating multiple paths to same action)
  get 'members', to: 'crew_members#index', as: :members
  get 'members/:id', to: 'crew_members#show', as: :member

  # API routes
  namespace :api do
    namespace :v1 do
      resources :spaceships, only: %i[index show]
      resources :crew_members, only: %i[index show]
    end
  end

  # Admin routes
  namespace :admin do
    resources :spaceships
    resources :crew_members
    resources :missions
  end
end
