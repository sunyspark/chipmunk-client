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
  end
end