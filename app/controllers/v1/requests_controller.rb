module V1
  class RequestsController < ApplicationController

    # GET /v1/requests
    def index
      @request_records = policy_scope(Request)
    end

    # GET /v1/requests/:bag_id
    def show
      @request_record = Request.find_by_bag_id!(params[:bag_id])
      authorize @request_record
    end

    # POST /v1/requests
    def create
      authorize Request
      existing_record = Request.find_by_bag_id(params[:request][:bag_id])
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
      params.require(:request).permit([:bag_id, :external_id, :content_type])
        .to_h
        .symbolize_keys
    end

  end

end
