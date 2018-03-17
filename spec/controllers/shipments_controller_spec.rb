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
  let(:order) { create(:order) }
  let(:order_id) { order.id }

  before(:each) do
    request.headers['HTTP_AUTHORIZATION'] = "Bearer #{ENV['HTTP_AUTH_TOKENS']}"
  end

  describe "GET #index" do
    it "returns a success response" do
      shipment = Shipment.create! valid_attributes
      get :index, params: {}, session: valid_session
    end

    # USPS Tracking numbers are 20,22,26 or 30 digits. The norm is 26 for Shippo.
    # 34 digit tracking numbers are an application code + zip code + 26 digit tracking number
    it "shortens a 34 digit USPS tracking number to a 26 digit one" do
      shipment = create(:label_created)

      get :index, params: { tracking_number: "42010001#{shipment.tracking_number}"}, session: valid_session

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)['data']
      expect(data['tracking_number']).to eq(shipment.tracking_number)
    end

    it "handles a failed look up by tracking number and returns a 404 and errors" do
      shipment = create(:label_created)
      tracking_number = "42010008881#{shipment.tracking_number}"

      expect{ get :index, params: { tracking_number: tracking_number}, session: valid_session }
        .to raise_error(NoShipmentFound)

      expect(response).to have_http_status(:not_found)
      data = JSON.parse(response.body)['data']
      errors = JSON.parse(response.body)['errors']
      expect(data).to eq []
      expect(errors).to eq ["Error looking up shipment #{tracking_number}"]
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

      it "defaults to economy shipment priority" do
        post :create, params: { order_id: order_id, shipment: valid_attributes }, session: valid_session
        body = JSON.parse(response.body)['data']
        
        expect(response).to have_http_status(:created)
        expect(body['shipment_priority']).to eq 'economy'
      end

      context 'without a tracking number' do

        let(:create_label_params)  { {
          shipment: {
            address_from: {
              :name => 'Centerline Labs',
              :company => '',
              :street1 => '814 Lincoln Pl',
              :street2 => '#2',
              :city => 'Brooklyn',
              :state => 'NY',
              :zip => '11216',
              :country => 'US',
              :phone => '123-456-7890',
              :email => 'info@thepublicrad.io'
            },
            address_to: {
              :name => order.name,
              :company => '',
              :street1 => '123 West 9th St.',
              :street2 => 'Apt 4',
              :city => 'Brooklyn',
              :state => 'NY',
              :zip => '11221',
              :country => 'US',
              :phone => '123-321-1231',
              :email => order.email
            },
            parcels: {
              :length => 5,
              :width => 4,
              :height => 3,
              :distance_unit => :in,
              :weight => 12,
              :mass_unit => :oz
            }
          },
          # Default is economy shipping
          servicelevel_token: "usps_first",
          carrier_account: "d2ed2a63bef746218a32e15450ece9d9"
        }}

        let(:shippo_response_object) { object_double('shippo response', code: 200,
          'status'=> 'SUCCESS', tracking_number: '9400111298370829688891',
          label_url: 'https://shippo-delivery-east.s3.amazonaws.com/some_label.pdf')
        }

        let(:valid_shipping_attributes) do
          valid_attributes.delete('tracking_number')
          valid_attributes['frequencies'] = ['98.1']
          valid_attributes
        end

        before(:each) do
          create_label_params[:shipment][:address_to][:name] = order.name
        end

        context 'and succeeds to' do

          def execute_post
            expect(Shippo::Transaction).to receive(:create).with(create_label_params).and_return(shippo_response_object).once
            post :create, params: { order_id: order_id, shipment: valid_shipping_attributes }, session: valid_session
          end

          before(:each) do
            expect(shippo_response_object).to receive(:[]).with('status').and_return('SUCCESS')
            expect(shippo_response_object).to receive(:tracking_number).and_return('9400111298370829688891')
            expect(shippo_response_object).to receive(:label_url).and_return('https://shippo-delivery-east.s3.amazonaws.com/some_label.pdf')
          end 

          it 'create a tracking number and label from the Shippo API' do
            # Sample create label reponse object
            # => #<Transaction:0x3ff8084b9f70[id=7eac98cbcd0e4f47b0f8c143c3e91331]{"object_state"=>"VALID", "status"=>"SUCCESS", "object_created"=>"2017-09-10T20:32:21.436Z", "object_updated"=>"2017-09-10T20:32:23.455Z", "object_id"=>"7eac98cbcd0e4f47b0f8c143c3e91331", "object_owner"=>"info@thepublicrad.io", "test"=>true, "rate"=>{"object_id"=>"0ca3611323ea4eefb8c660aeedae3212", "amount"=>"6.66", "currency"=>"USD", "amount_local"=>"6.66", "currency_local"=>"USD", "provider"=>"USPS", "servicelevel_name"=>"Priority Mail", "servicelevel_token"=>"usps_priority", "carrier_account"=>"d2ed2a63bef746218a32e15450ece9d9"}, "tracking_number"=>"92055901755477000000000015", "tracking_status"=>"UNKNOWN", "eta"=>nil, "tracking_url_provider"=>"https://tools.usps.com/go/TrackConfirmAction_input?origTrackNum=92055901755477000000000015", "label_url"=>"https://shippo-delivery-east.s3.amazonaws.com/7eac98cbcd0e4f47b0f8c143c3e91331.pdf?Signature=b0ovKkUqrhyiZfDPYk%2F3SpTlJUo%3D&Expires=1536611542&AWSAccessKeyId=AKIAJGLCC5MYLLWIG42A", "commercial_invoice_url"=>nil, "messages"=>[], "order"=>nil, "metadata"=>"", "parcel"=>"01f2dc092d8e467db5321eadd903ce36", "billing"=>{"payments"=>[]}}->#<Shippo::API::ApiObject created=2017-09-10 20:32:21 UTC id="7eac98cbcd0e4f47b0f8c143c3e91331" owner="info@thepublicrad.io" state=#<Shippo::API::Category::State:0x007ff011b265c0 @name=:state, @value=:valid> updated=2017-09-10 20:32:23 UTC>

            Timecop.freeze('2017-08-06')

            execute_post

            body = JSON.parse(response.body)['data']
            expect(Shipment.find(body['id']).tracking_number).to eq(shippo_response_object.tracking_number)
            expect(Shipment.find(body['id']).shipment_status).to eq 'label_created'
          end

          it 'creates tracking number for international orders' do
            Timecop.freeze('2017-08-06')
            international_order = create(:international_order)

            customs_item = {
              :description => "Single station FM radio",
              :quantity => 1,
              :net_weight => "12",
              :mass_unit => "oz",
              :value_amount => "40",
              :value_currency => "USD",
              :origin_country => "US"
            }

            customs_declaration_options = {
              :contents_type => "MERCHANDISE",
              :contents_explanation => "Single station FM radio",
              :non_delivery_option => "ABANDON",
              :certify => true,
              :certify_signer => "Spencer Wright",
              :items => [customs_item]
            }

            customs_declaration_response = object_double('customs_declaration', valid: true)

            expect(Shippo::CustomsDeclaration).to receive(:create).with(customs_declaration_options)
              .and_return(customs_declaration_response)

            create_label_params[:shipment][:address_to] = {
              :name => international_order.name,
              :company => '',
              :street1 => international_order.street_address_1,
              :street2 => international_order.street_address_2,
              :city => international_order.city,
              :state => international_order.state,
              :zip => international_order.postal_code,
              :country => international_order.country,
              :phone => international_order.phone,
              :email => international_order.email
            }

            create_label_params[:shipment][:customs_declaration] = customs_declaration_response
            create_label_params[:servicelevel_token] = 'usps_first_class_package_international_service'
            valid_shipping_attributes['order_id'] = international_order.id

            expect(Shippo::Transaction).to receive(:create).with(create_label_params).and_return(shippo_response_object).once
            post :create, params: { order_id: international_order.id, shipment: valid_shipping_attributes }, session: valid_session

            body = JSON.parse(response.body)['data']
            expect(Shipment.find(body['id']).tracking_number).to eq(shippo_response_object.tracking_number)
            expect(body['tracking_number']).to eq shippo_response_object.tracking_number
          end

          it 'stores the label_url from the shippo response' do
            execute_post
            expect(Shipment.last.label_url).to eq(shippo_response_object.label_url)
          end

          it 'creates a return label if the order_source is warranty' do
            create_return_label_params[:extra] = { :is_return => true }
            expect(Shippo::Transaction).to receive(:create).with(create_label_params).and_return(shippo_response_object).once
            expect(Shippo::Shipment).to receive(:create).with(create_return_label_params).and_return(shippo_response_object).once
            
            post :create, params: { order_id: order_id, shipment: valid_shipping_attributes }, session: valid_session
          end

          it 'creates express shipments' do
            valid_attributes['shipment_priority'] = 'express'
            create_label_params[:servicelevel_token] = 'usps_priority_express'
            execute_post
            expect(Shipment.last.shipment_priority).to eq('express')
            expect(Shipment.last.priority_processing).to be true
          end

          it 'creates priority shipments' do
            valid_attributes['shipment_priority'] = 'priority'
            create_label_params[:servicelevel_token] = 'usps_priority'
            execute_post
            expect(Shipment.last.shipment_priority).to eq('priority')
          end
        end

        it 'handles errors from Shippo and raises an exception' do
          # Sample error object
          # => #<Transaction:0x3ff808e2f3ac[id=91bdbecdc6ca49689b4984670dc52393]{"object_state"=>"VALID", "status"=>"ERROR", "object_created"=>"2017-09-10T20:25:46.898Z", "object_updated"=>"2017-09-10T20:25:47.952Z", "object_id"=>"91bdbecdc6ca49689b4984670dc52393", "object_owner"=>"info@thepublicrad.io", "test"=>true, "rate"=>{"object_id"=>"33c2904f50384420988c1329f1a988fc", "amount"=>"7.18", "currency"=>"USD", "amount_local"=>"7.18", "currency_local"=>"USD", "provider"=>"USPS", "servicelevel_name"=>"Priority Mail", "servicelevel_token"=>"usps_priority", "carrier_account"=>"d2ed2a63bef746218a32e15450ece9d9"}, "tracking_number"=>"", "tracking_status"=>"UNKNOWN", "eta"=>nil, "tracking_url_provider"=>"", "label_url"=>"", "commercial_invoice_url"=>nil, "messages"=>[#<Hashie::Mash code="" source="USPS" text="Recipient address invalid: The address as submitted could not be found. Please check for excessive abbreviations in the street address line or in the City name.">], "order"=>nil, "metadata"=>"", "parcel"=>"588d1166330b46778f666bc808e216ec", "billing"=>{"payments"=>[]}}->#<Shippo::API::ApiObject created=2017-09-10 20:25:46 UTC id="91bdbecdc6ca49689b4984670dc52393" owner="info@thepublicrad.io" state=#<Shippo::API::Category::State:0x007ff011b265c0 @name=:state, @value=:valid> updated=2017-09-10 20:25:47 UTC>
          create_label_error_response = object_double('error', success?: false, status: 'ERROR',
            messages: object_double('message', text: 'Recipient address invalid: The address as submitted could not be found. Please check for excessive abbreviations in the street address line or in the City name.') )

          expect(create_label_error_response).to receive(:[]).with('status').and_return('FAILURE')

          expect(Shippo::Transaction).to receive(:create).with(create_label_params).and_return(create_label_error_response)

          expect{
            post :create, params: { order_id: order_id, shipment: valid_shipping_attributes }, session: valid_session
            }.to raise_error(ShippoError)
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

      it 'updates the ship_date when the status changes to shipped' do
        expected_date = '2017-09-03'
        Timecop.freeze('2017-09-04')

        shipment = Shipment.create! valid_attributes

        put :update, params: {id: shipment.to_param, shipment: { shipment_status: 'shipped' }}, session: valid_session
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)['data']
        expect(data['ship_date']).to eq(expected_date)
        expect(Shipment.find(shipment.id).ship_date).to eq(expected_date)
      end

      it 'updates the ship_date when the status changes to shipped' do
        expected_date = '2017-09-03'
        Timecop.freeze('2017-09-04')

        shipment = Shipment.create! valid_attributes

        put :update, params: {id: shipment.to_param, shipment: { shipment_status: 'shipped' }}, session: valid_session
        expect(response).to have_http_status(:ok)
        data = JSON.parse(response.body)['data']
        expect(data['ship_date']).to eq(expected_date)
        expect(Shipment.find(shipment.id).ship_date).to eq(expected_date)
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
