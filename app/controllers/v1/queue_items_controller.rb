# frozen_string_literal: true

module V1
  class QueueItemsController < ApplicationController
    # GET /v1/queue
    def index
      @queue_items = policy_scope(QueueItem)
    end

    # GET /v1/queue/:id
    def show
      @queue_item = QueueItem.find(params[:id])
      authorize @queue_item
      render template: "v1/queue_items/show", status: 200
    end

    # POST /v1/requests/:bag_id/complete
    def create
      skip_authorization # disables did-not-auth protection
      request = Bag.find_by_bag_id!(params[:bag_id])
      authorize_create!(request)
      status, @queue_item = QueueItemBuilder.new.create(request)
      case status
      when :duplicate
        head 303, location: v1_queue_item_path(@queue_item)
      when :created
        head 201, location: v1_queue_item_path(@queue_item)
      when :invalid
        render json: @queue_item.errors, status: :unprocessable_entity
      else
        raise [status, @queue_item]
      end
    end

    private

    def authorize_create!(request)
      policy = QueueItemPolicy.new(current_user, QueueItem)
      unless policy.create?(request)
        raise Pundit::NotAuthorizedError, "not allowed to create? this QueueItem for #{params[:bag_id]}"
      end
    end

  end

end
