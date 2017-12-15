# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :v1 do
    resources :requests, controller: :bags, only: [:index, :show, :create], param: :bag_id
    post "/requests/:bag_id/complete", controller: :queue_items, action: :create
    resources :bags, only: [:index, :show], param: :bag_id

    # We foresee the need for destroy; currently out of scope.
    resources :queue_items, only: [:index, :show], path: :queue
  end
end
