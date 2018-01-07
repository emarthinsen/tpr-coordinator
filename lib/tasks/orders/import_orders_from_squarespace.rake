require 'squarespace'
namespace :orders do
  desc "Import squarespace orders"
  task import_orders_from_squarespace: :environment do
  	client = Squarespace::Client.new(app_name: ENV['SQUARESPACE_APP_NAME'], api_key: ENV['SQUARESPACE_API_KEY'])

  	orders = client.get_orders('pending')

  	orders.each do |order|
  	  shipping_address = order[:shippingAddress]
      frequency_list = []
      country_code = ''

      order[:lineItems][0].each do |c|
          case c[:label]
          when 'Tuning frequency'
              frequency = c[:value]
          when 'Where will you be using your radio?'
              country_code = c[:value]
          end
      end

      order[:lineItems][0][:quantity].times do
          frequency_list << frequency
      end

      order_params = {
          name: "#{shipping_address[:firstName]} #{shipping_address[:lastName]}",
          order_source: "squarespace",
          email: order['customerEmail'],
          street_address_1: shipping_address['address1'],
          street_address_2: shipping_address['address2'],
          city: shipping_address['city'],
          state: shipping_address['state'],
          postal_code: shipping_address['postalCode'],
          country: shipping_address[:countryCode], # they only ship to US
          phone: shipping_address['phone'],
          reference_number: "#{order[:id]},#{order[:orderNumber]}", # Squarespace order number
          shipment_priority: 'economy',
          frequencies: frequency_list
      }

      TaskHelper.create_order(order_params)
    end
  end
end