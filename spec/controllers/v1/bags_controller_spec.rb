# frozen_string_literal: true

require "rails_helper"

RSpec.describe V1::BagsController, type: :controller do
  describe "/v1" do
    describe "GET #index" do
      it_behaves_like "an index endpoint" do
        let(:key) { :bag_id }
        let(:factory) do
          proc {|user| user ? Fabricate(:bag, user: user) : Fabricate(:bag) }
        end
        let(:assignee) { :bags }
      end
    end

    describe "GET #show" do
      it_behaves_like "a show endpoint" do
        let(:key) { :bag_id }
        let(:factory) do
          proc {|user| user ? Fabricate(:bag, user: user) : Fabricate(:bag) }
        end
        let(:assignee) { :bag }
      end
    end

    describe "GET #show/:external_id" do
      context "as an admin" do
        include_context "as admin user"
        let(:bag) { Fabricate(:bag) }

        it "can fetch a bag by external id" do
          request.headers.merge! auth_header
          get :show, params: { :bag_id => bag.external_id }

          expect(assigns(:bag)).to eql(bag)
        end
      end
    end

    describe "POST #create" do
      let(:attributes) do
        {
          bag_id:       SecureRandom.uuid,
          content_type: "audio",
          external_id:  SecureRandom.uuid
        }
      end

      shared_context "mocked RequestBuilder" do |status|
        let(:result_request) do
          Fabricate(:bag,
            bag_id: attributes[:bag_id],
            user: user,
            external_id: attributes[:external_id],
            content_type: attributes[:content_type])
        end
        let(:result_status) { status }
        let(:builder) { double(:builder) }
        before(:each) do
          allow(RequestBuilder).to receive(:new).and_return(builder)
          allow(builder).to receive(:create).and_return([result_status, result_request])
        end
      end

      before(:each) do
        request.headers.merge! auth_header
      end

      context "as unauthenticated user" do
        include_context "as unauthenticated user"
        it "returns 401" do
          post :create, params: attributes
          expect(response).to have_http_status(401)
        end
        it "renders nothing" do
          post :create, params: attributes
          expect(response).to render_template(nil)
        end
        it "does not create the record" do
          post :create, params: attributes
          expect(Bag.count).to eql(0)
        end
      end
      context "as authenticated user" do
        include_context "as underprivileged user"
        context "new record" do
          context "RequestBuilder returns a valid record" do
            include_context "mocked RequestBuilder", :created

            it "passes the parameters to a RequestBuilder" do
              post :create, params: attributes
              expect(RequestBuilder).to have_received(:new)
              expect(builder).to have_received(:create).with(attributes.merge(user: user))
            end
            it "returns 201" do
              post :create, params: attributes
              expect(response).to have_http_status(201)
            end
            it "correctly sets the location header" do
              post :create, params: attributes
              expect(response.location).to eql(v1_request_path(result_request))
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "RequestBuilder returns an invalid record" do
            include_context "mocked RequestBuilder", :invalid
            it "returns 422" do
              post :create, params: attributes
              expect(response).to have_http_status(422)
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
        end
        context "as duplicate record" do
          include_context "mocked RequestBuilder", :duplicate
          it "does not create an additional record" do
            post :create, params: attributes
            expect(Bag.count).to eql(1)
          end
          it "returns 303" do
            post :create, params: attributes
            expect(response).to have_http_status(303)
          end
          it "correctly sets the location header" do
            post :create, params: attributes
            expect(response.location).to eql(v1_request_path(result_request))
          end
          it "renders nothing" do
            post :create, params: attributes
            expect(response).to render_template(nil)
          end
        end
      end
    end
  end
end
