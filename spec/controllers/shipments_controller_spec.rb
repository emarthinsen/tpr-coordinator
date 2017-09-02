require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.
#
# Also compared to earlier versions of this generator, there are no longer any
# expectations of assigns and templates rendered. These features have been
# removed from Rails core in Rails 5, but can be added back in via the
# `rails-controller-testing` gem.

RSpec.describe ShipmentsController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Shipment. As you add validations to Shipment, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { build(:shipment).attributes }

  let(:invalid_attributes) {
    {
      tracking_number: "not a usps tracking number",
      shipment_status: '93203'
    }
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # ShipmentsController. Be sure to keep this updated too.
  let(:valid_session) { {} }
  let(:order) { build(:order) }
  let(:order_id) { order.id }

  describe "GET #index" do
    it "returns a success response" do
      shipment = Shipment.create! valid_attributes
      get :index, params: {}, session: valid_session
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      shipment = Shipment.create! valid_attributes
      get :show, params: {id: shipment.to_param}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Shipment" do
        expect {
          post :create, params: { order_id: order_id, shipment: valid_attributes }, session: valid_session
        }.to change(Shipment, :count).by(1)
      end

      it "renders a JSON response with the new shipment" do
        post :create, params: { order_id: order_id, shipment: valid_attributes }, session: valid_session
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
      end

      context 'without a tracking number' do
        create_label_params = load_json_fixture('./spec/fixtures/shipstation/create_label_request_options.json')
        create_label_response = load_fixture('./spec/fixtures/shipstation/create_label_response.json')
        create_label_error_response = load_fixture('./spec/fixtures/shipstation/create_label_error_response.json')

        it 'creates a tracking number from the shipstation API' do
          shipstation_response_object = object_double('response', status: 200, body: create_label_response )

          valid_attributes.delete('tracking_number')

          url = 'https://ssapi.shipstation.com/shipments/createlabel'
          headers = { 
            "Authorization" => "Basic #{Base64.strict_encode64('test_api_key:test_api_secret')}"
          }

          Timecop.freeze('2017-08-06')

          expect(HTTParty).to receive(:post).with(url, headers: headers, body: create_label_params).and_return(shipstation_response_object)
          post :create, params: { order_id: order_id, shipment: valid_attributes }, session: valid_session

          body = JSON.parse(response.body)['data']
          expect(Shipment.find(body['id']).tracking_number).to eq(JSON.parse(create_label_response)['trackingNumber'])
        end

        it 'handles errors from shipstation and raises an exception' do
          shipstation_response_object = object_double('response', status: 500, body: create_label_error_response)

          valid_attributes.delete('tracking_number')

          Timecop.freeze('2017-08-06')

          expect(HTTParty).to receive(:post).and_return(shipstation_response_object)
          expect{ 
            post :create, params: { order_id: order_id, shipment: valid_attributes }, session: valid_session
            }.to raise_error(ShipstationError)
        end
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new shipment" do

        post :create, params: {shipment: invalid_attributes}, session: valid_session
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        {
          shipment_status: 'shipped'
        }
      }

      it "updates the requested shipment" do
        shipment = Shipment.create! valid_attributes
        put :update, params: {id: shipment.to_param, shipment: new_attributes}, session: valid_session
        shipment.reload
        expect(shipment.shipment_status).to eq(new_attributes[:shipment_status])
      end

      it "renders a JSON response with the shipment" do
        shipment = Shipment.create! valid_attributes

        put :update, params: {id: shipment.to_param, shipment: valid_attributes}, session: valid_session
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the shipment" do
        shipment = Shipment.create! valid_attributes

        put :update, params: {id: shipment.to_param, shipment: invalid_attributes}, session: valid_session
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested shipment" do
      shipment = Shipment.create! valid_attributes
      expect {
        delete :destroy, params: {id: shipment.to_param}, session: valid_session
      }.to change(Shipment, :count).by(-1)
    end
  end
end
