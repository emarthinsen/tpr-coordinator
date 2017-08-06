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

RSpec.describe OrdersController, type: :controller do

  # This should return the minimal set of attributes required to create a valid
  # Order. As you add validations to Order, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) { build(:order).attributes  }

  let(:invalid_attributes) { build(:order, order_source: 'amazon').attributes }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # OrdersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      order = Order.create! valid_attributes
      get :index, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      order = Order.create! valid_attributes
      get :show, params: {id: order.to_param}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new Order" do
        expect {
          post :create, params: {order: valid_attributes}, session: valid_session
        }.to change(Order, :count).by(1)
      end

      it "renders a JSON response with the new order" do

        post :create, params: {order: valid_attributes}, session: valid_session
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json')
        expect(response.location).to eq(order_url(Order.last))
      end
    end

    context "with a frequency list" do

      it "creates a shipment for each set of 3 radios" do
        frequencies = ['98.3', '79.5', '79.5', '98.3', '79.5', '79.5', '98.3', '79.5', '79.5', '105.6']

        expect{
          post :create, params: { frequencies: frequencies, order: valid_attributes }, session: valid_session
        }.to change(Shipment, :count).by(4)

        shipments = Shipment.all[-4..-1]
        expect(shipments.select{ |s| s.radio.count == 3 }.count).to be 3
        expect(shipments.select{ |s| s.radio.count == 1 }.count).to be 1
      end

      it "creates a radio for each entry in the list" do
        frequencies = ['98.3', '79.5', '79.5', '98.3', '79.5', '79.5', '98.3', '79.5', '79.5', '105.6']

        expect{
          post :create, params: { frequencies: frequencies, order: valid_attributes }, session: valid_session
        }.to change(Radio, :count).by(10)

        radios = Radio.all[-10..-1]

        expect(radios.select{ |r| r.frequency == '79.5' }.count).to be 6
        expect(radios.select{ |r| r.frequency == '105.6' }.count).to be 1
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the new order" do

        post :create, params: {order: invalid_attributes}, session: valid_session
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_email) { 'new@email.com' }
      let(:new_attributes) {
        build(:order, email: new_email ).attributes
      }

      it "updates the requested order" do
        order = Order.create! valid_attributes
        put :update, params: {id: order.to_param, order: new_attributes}, session: valid_session
        order.reload
        expect(order.email).to eq(new_email)
      end

      it "renders a JSON response with the order" do
        order = Order.create! valid_attributes

        put :update, params: {id: order.to_param, order: valid_attributes}, session: valid_session
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json')
      end
    end

    context "with invalid params" do
      it "renders a JSON response with errors for the order" do
        order = Order.create! valid_attributes

        put :update, params: {id: order.to_param, order: invalid_attributes}, session: valid_session
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to eq('application/json')
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested order" do
      order = Order.create! valid_attributes
      expect {
        delete :destroy, params: {id: order.to_param}, session: valid_session
      }.to change(Order, :count).by(-1)
    end
  end
end
