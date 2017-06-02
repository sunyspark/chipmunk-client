require 'rails_helper'

RSpec.describe V1::QueueItemsController, type: :controller do
  describe "/v1" do

    pending_proc = proc do |user|
      if user
        Fabricate(:queue_item,
          bag: nil,
          request: Fabricate(:request, user: user))
      else
        Fabricate(:queue_item, bag: nil)
      end
    end

    done_proc = proc do |user|
      uuid = SecureRandom.uuid
      if user
        Fabricate(:queue_item,
          bag: Fabricate(:bag, bag_id: uuid, user: user),
          request: Fabricate(:request, bag_id: uuid, user: user)
        )
      else
        Fabricate(:queue_item,
          bag: Fabricate(:bag, bag_id: uuid),
          request: Fabricate(:request, bag_id: uuid)
        )
      end
    end

    describe "GET #index" do
      it_behaves_like "an index endpoint" do
        before(:each) do
          # We invoke the done_proc here to add an additional,
          # non-pending (complete) queue item.  Its existence
          # will cause the tests to fail if it is retrieved by
          # the index endpoint.
          # This is a hack.
          done_proc.call(user)
        end
        let(:key) { :id }
        let(:factory) { pending_proc }
        let(:assignee) { :queue_items }
      end
    end

    describe "GET #show" do
      context "queue_item has no bag (is incomplete)" do
        it_behaves_like "a show endpoint" do
          let(:key) { :id }
          let(:factory) { pending_proc }
          let(:assignee) { :queue_item }
        end
      end
      context "queue_item has a bag (is complete)" do
        before(:each) do
          request.headers.merge! auth_header
          get :show, params: {id: record.id}
        end
        context "as unauthenticated user" do
          include_context "as unauthenticated user"
          let(:record) { done_proc.call }
          it "returns 401" do
            expect(response).to have_http_status(401)
          end
          it "renders nothing" do
            expect(response).to render_template(nil)
          end
        end
        context "as underprivileged user" do
          include_context "as underprivileged user"
          context "the record belongs to the user" do
            let(:record) { done_proc.call(user) }
            it "returns 303" do
              expect(response).to have_http_status(303)
            end
            it "correctly sets the location header" do
              expect(response.location).to eql(v1_bag_url(record.bag))
            end
            it "renders nothing" do
              expect(response).to render_template(nil)
            end
          end
          context "the record does not belong to the user" do
            let(:record) { done_proc.call }
            it "returns 403" do
              expect(response).to have_http_status(403)
            end
            it "renders nothing" do
              expect(response).to render_template(nil)
            end
          end
        end
        context "as admin" do
          include_context "as admin user"
          context "the record belongs to the user" do
            let(:record) { done_proc.call(user) }
            it "returns 303" do
              expect(response).to have_http_status(303)
            end
            it "correctly sets the location header" do
              expect(response.location).to eql(v1_bag_url(record.bag))
            end
            it "renders nothing" do
              expect(response).to render_template(nil)
            end
          end
          context "the record does not belong to the user" do
            let(:record) { done_proc.call }
            it "returns 303" do
              expect(response).to have_http_status(303)
            end
            it "correctly sets the location header" do
              expect(response.location).to eql(v1_bag_url(record.bag))
            end
            it "renders nothing" do
              expect(response).to render_template(nil)
            end
          end
        end
      end

    end

    describe "POST #create" do
      let(:attributes) {{ bag_id: SecureRandom.uuid }}
      let(:builder) { double(:builder, build: nil) }
      before(:each) do
        allow(QueueItemBuilder).to receive(:new).and_return(builder)
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
          expect(QueueItem.count).to eql(0)
        end
      end

      context "as underprivileged user" do
        include_context "as underprivileged user"
        context "duplicate record" do
          let!(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id], user: user) }
          let!(:expected_record) { Fabricate(:queue_item, request: request_record) }
          before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
          it "does not invoke QueueItemBuilder" do
            expect(QueueItemBuilder).to_not receive(:new)
            post :create, params: attributes
          end
          it "does not create an additional record" do
            post :create, params: attributes
            expect(QueueItem.count).to eql(1)
          end
          it "returns 303" do
            post :create, params: attributes
            expect(response).to have_http_status(303)
          end
          it "correctly sets the location header" do
            post :create, params: attributes
            expect(response.location).to eql(v1_queue_item_url(expected_record))
          end
          it "renders nothing" do
            post :create, params: attributes
            expect(response).to render_template(nil)
          end
        end
        context "new record" do
          before(:each) { allow(QueueItem).to receive_message_chain(:joins, :find_by).and_return nil }
          context "user owns request, success" do
            let(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id], user: user) }
            let(:expected_record) { Fabricate(:queue_item, request: request_record) }
            before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
            it "returns 201" do
              post :create, params: attributes
              expect(response).to have_http_status(201)
            end
            it "correctly sets location header" do
              post :create, params: attributes
              expect(response.location).to eql(v1_queue_item_url(expected_record))
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "user owns request, failure" do
            let(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id], user: user) }
            let(:expected_record) do
              record = Fabricate(:queue_item, request: request_record)
              record.errors.add(:bag, message: "test_error")
              record
            end
            before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
            it "returns 422" do
              post :create, params: attributes
              expect(response).to have_http_status(422)
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "user does not own request, success" do
            let(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id])}
            let(:expected_record) { Fabricate(:queue_item, request: request_record) }
            before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
            it "returns 403" do
              post :create, params: attributes
              expect(response).to have_http_status(403)
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "user does not own request, failure" do
            let(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id]) }
            let(:expected_record) do
              record = Fabricate(:queue_item, request: request_record)
              record.errors.add(:bag, message: "test_error")
              record
            end
            before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
            it "returns 403" do
              post :create, params: attributes
              expect(response).to have_http_status(403)
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
        end

      end
      context "as admin user" do
        include_context "as admin user"
        context "duplicate record" do
          let!(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id], user: user) }
          let!(:expected_record) { Fabricate(:queue_item, request: request_record) }
          before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
          it "does not invoke QueueItemBuilder" do
            expect(QueueItemBuilder).to_not receive(:new)
            post :create, params: attributes
          end
          it "does not create an additional record" do
            post :create, params: attributes
            expect(QueueItem.count).to eql(1)
          end
          it "returns 303" do
            post :create, params: attributes
            expect(response).to have_http_status(303)
          end
          it "correctly sets the location header" do
            post :create, params: attributes
            expect(response.location).to eql(v1_queue_item_url(expected_record))
          end
          it "renders nothing" do
            post :create, params: attributes
            expect(response).to render_template(nil)
          end
        end
        context "new record" do
          before(:each) { allow(QueueItem).to receive_message_chain(:joins, :find_by).and_return nil }
          context "user owns request, success" do
            let(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id], user: user) }
            let(:expected_record) { Fabricate(:queue_item, request: request_record) }
            before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
            it "returns 201" do
              post :create, params: attributes
              expect(response).to have_http_status(201)
            end
            it "correctly sets location header" do
              post :create, params: attributes
              expect(response.location).to eql(v1_queue_item_url(expected_record))
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "user owns request, failure" do
            let(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id], user: user) }
            let(:expected_record) do
              record = Fabricate(:queue_item, request: request_record)
              record.errors.add(:bag, message: "test_error")
              record
            end
            before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
            it "returns 422" do
              post :create, params: attributes
              expect(response).to have_http_status(422)
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "user does not own request, success" do
            let(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id])}
            let(:expected_record) { Fabricate(:queue_item, request: request_record) }
            before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
            it "returns 201" do
              post :create, params: attributes
              expect(response).to have_http_status(201)
            end
            it "correctly sets location header" do
              post :create, params: attributes
              expect(response.location).to eql(v1_queue_item_url(expected_record))
            end
            it "renders nothing" do
              post :create, params: attributes
              expect(response).to render_template(nil)
            end
          end
          context "user does not own request, failure" do
            let(:request_record) { Fabricate(:request, bag_id: attributes[:bag_id]) }
            let(:expected_record) do
              record = Fabricate(:queue_item, request: request_record)
              record.errors.add(:bag, message: "test_error")
              record
            end
            before(:each) { allow(builder).to receive(:create).and_return(expected_record) }
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

      end

    end

  end
end
