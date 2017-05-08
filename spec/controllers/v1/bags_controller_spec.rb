require 'rails_helper'

RSpec.describe V1::BagsController, type: :controller do
  describe "/v1" do

    describe "GET #index" do
      it_behaves_like "an index endpoint" do
        let(:key) { :bag_id }
        let(:factory) {
          proc {|user| user ? Fabricate(:bag, user: user) : Fabricate(:bag) }
        }
        let(:assignee) { :bags }
      end
    end

    describe "GET #show" do
      it_behaves_like "a show endpoint" do
        let(:key) { :bag_id }
        let(:factory) {
          proc {|user| user ? Fabricate(:bag, user: user) : Fabricate(:bag) }
        }
        let(:assignee) { :bag }
      end
    end

  end
end
