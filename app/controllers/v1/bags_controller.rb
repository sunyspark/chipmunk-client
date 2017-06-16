module V1
  class BagsController < ApplicationController

    # GET /bags
    def index
      @bags = policy_scope(Bag)
    end

    # GET /bags/1
    def show
      @bag = Bag.find_by_bag_id(params[:bag_id])
      authorize @bag
    end

    # POST /v1/requests
    def create
      authorize Bag
      existing_record = Bag.find_by_bag_id(params[:bag_id])
      if existing_record
        head 303, location: v1_request_url(existing_record)
      else
        @request_record = RequestBuilder.new(create_params.merge({user: current_user}))
          .create
        if @request_record.errors.empty?
          head 201, location: v1_request_url(@request_record)
        else
          render json: @request_record.errors, status: :unprocessable_entity
        end
      end
    end

    private

    def create_params
      params.permit([:bag_id, :external_id, :content_type])
        .to_h
        .symbolize_keys
    end

  end
end