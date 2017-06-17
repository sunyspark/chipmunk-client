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

    describe "POST #create" do
      let(:attributes) do
        {
          bag_id: SecureRandom.uuid,
          content_type: "audio",
          external_id: SecureRandom.uuid
        }
      end
      let(:request_builder) { double(:request_builder, build: nil) }
      let(:expected_record) do
        Fabricate(:request,
          bag_id: attributes[:bag_id],
          user: user,
          external_id: attributes[:external_id],
          content_type: attributes[:content_type]
        )
      end
      before(:each) do
        allow(RequestBuilder).to receive(:new).and_return(request_builder)
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
          before(:each) do
            # mock the search to return nil; we must do this because we're mocking
            # the return of RequestBuilder#build
            allow(Bag).to receive(:find_by_bag_id).with(attributes[:bag_id])
              .and_return nil
          end
          context "RequestBuilder returns a valid record" do
            before(:each) do
              allow(request_builder).to receive(:create).and_return(expected_record)
            end
            it "passes the parameters to a RequestBuilder" do
              post :create, params: attributes
              expect(RequestBuilder).to have_received(:new).with(attributes.merge({user: user}))
              expect(request_builder).to have_received(:create)
            end
            it "returns 201" do
              post :create, params: attributes
              expect(response).to have_http_status(201)
            end
            it "correctly sets the location header" do
              post :create, params: attributes
              expect(response.location).to eql(v1_request_path(expected_record))
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "RequestBuilder returns an invalid record" do
            before(:each) do
              record = Fabricate.build(:request, user: nil)
              record.valid?
              allow(request_builder).to receive(:create).and_return(record)
            end
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
          before(:each) { expected_record } # fabricates our record
          it "does not invoke RequestBuilder" do
            expect(RequestBuilder).to_not receive(:new)
            post :create, params: attributes
          end
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
            expect(response.location).to eql(v1_request_path(expected_record))
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
