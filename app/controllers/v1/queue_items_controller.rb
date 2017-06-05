module V1
  class QueueItemsController < ApplicationController
    # GET /v1/queue
    def index
      @queue_items = policy_scope(QueueItem).where(bag: nil)
    end

    # GET /v1/queue/:id
    def show
      @queue_item = QueueItem.find(params[:id])
      authorize @queue_item
      if @queue_item.bag
        head 303, location: v1_bag_url(@queue_item.bag)
      else
        render template: "v1/queue_items/show", status: 200
      end
    end

    # POST /v1/requests/:bag_id/complete
    def create
      skip_authorization #disables did-not-auth protection
      existing_record = QueueItem.joins(:request).find_by(requests: { bag_id: params[:bag_id]})
      if existing_record
        head 303, location: v1_queue_item_url(existing_record)
      else
        request = Request.find_by_bag_id(params[:bag_id])
        authorize_create!(request)
        @queue_item = QueueItemBuilder.new().create(request)
        if @queue_item.errors.empty?
          head 201, location: v1_queue_item_url(@queue_item)
        else
          render json: @queue_item.errors, status: :unprocessable_entity
        end
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
