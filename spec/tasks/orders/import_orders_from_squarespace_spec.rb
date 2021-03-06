require "rails_helper"
require 'squarespace'

describe "orders:import_orders_from_squarespace", type: :rake do

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  context 'from squarespace' do
    it 'import all pendings orders' do
        ENV['SEND_IMPORT_NOTIFICATION_EMAILS_SQUARESPACE'] = 'true'
        api_key = ENV['SQUARESPACE_API_KEY']
        app_name = ENV['SQUARESPACE_APP_NAME']

        squarespace_order_fixture = JSON.parse(load_fixture('spec/fixtures/squarespace_orders.json'))
        stub_client = instance_double(Squarespace::Client, :get_orders)

        stub_orders = Squarespace::Order.new(squarespace_order_fixture)

        expect(Squarespace::Client).to receive(:new).with(app_name: app_name, api_key: api_key)
            .and_return(stub_client)

        expect(stub_client).to receive(:get_orders).with('pending').and_return(stub_orders)

        squarespace_order_fixture['result'].each do |test_order|
            shipping_address = test_order['shippingAddress']

            radio_country = test_order['lineItems'][0]['customizations'][0]['value'][0..1]

            order_params = {
                name: "#{shipping_address['firstName']} #{shipping_address['lastName']}",
                order_source: "squarespace",
                email: test_order['customerEmail'],
                street_address_1: shipping_address['address1'],
                street_address_2: shipping_address['address2'],
                city: shipping_address['city'],
                state: shipping_address['state'],
                postal_code: shipping_address['postalCode'],
                country: shipping_address['countryCode'],
                phone: shipping_address['phone'],
                reference_number: "#{test_order['id']},#{test_order['orderNumber']}", # Squarespace order number
                shipment_priority: 'economy',
                frequencies: { radio_country => ['82.7','82.7','82.7','82.7'] }
            }

            expect_any_instance_of(TaskHelper).to receive(:create_order).with(order_params)
        end
        task.execute
    end
  end
end